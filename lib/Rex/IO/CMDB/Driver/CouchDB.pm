#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::CMDB::Driver::CouchDB;
   
use strict;
use warnings;

use Mojo::UserAgent;
use Mojo::JSON;
use Data::Dumper;
use Data::UUID::MT;
use Hash::Merge qw(merge);

Hash::Merge::specify_behavior(
            {
                        'SCALAR' => {
                                'SCALAR' => sub { $_[1] },
                                'ARRAY'  => sub { $_[1] },
                                'HASH'   => sub { $_[1] },
                        },
                        'ARRAY' => {
                                'SCALAR' => sub { $_[1] },
                                'ARRAY'  => sub { $_[1] },
                                'HASH'   => sub { $_[1] }, 
                        },
                        'HASH' => {
                                'SCALAR' => sub { $_[1] },
                                'ARRAY'  => sub { $_[1] },
                                'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) }, 
                        },
                }, 
                'My Behavior', 
        );

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub list_servers {
   my ($self) = @_;
   my $couch_db = $self->_db;
   my $tx = $self->_ua->get("$couch_db/_design/all/_view/servers");

   if (my $res = $tx->success) {
      my $ref = $self->_json->decode($res->body);
      my %servers = ();
      map { delete $_->{value}->{_id}; delete $_->{value}->{_rev}; $servers{$_->{value}->{name}} = $_->{value} } @{ $ref->{rows} };
      return \%servers;
   }
   else {
      # error in request
      my ($message, $code) = $tx->error;
      die($message);
   }
}

sub list_services {
   my ($self) = @_;
   my $couch_db = $self->_db;
   my $tx = $self->_ua->get("$couch_db/_design/all/_view/services");

   if (my $res = $tx->success) {
      my $ref = $self->_json->decode($res->body);
      my %services = ();
      map { delete $_->{value}->{_id}; delete $_->{value}->{_rev}; $services{$_->{value}->{name}} = $_->{value} } @{ $ref->{rows} };
      return \%services;
   }
   else {
      # error in request
      my ($message, $code) = $tx->error;
      die($message);
   }
}

sub get_server {
   my ($self, $server, %option) = @_;
   
   my $couch_db = $self->_db;
   my $tx = $self->_ua->post("$couch_db/_design/all/_view/servers",
                              { "Content-Type" => "application/json" },
                              '{ "keys": ["'.$server.'"] }');

   if (my $res = $tx->success) {
      my $ref = $self->_json->decode($res->body);
      if(scalar(@{ $ref->{rows} }) == 0) {
         return undef;
      }
      else {
         if(! exists $option{full}) {
            delete $ref->{rows}->[0]->{value}->{_id};
            delete $ref->{rows}->[0]->{value}->{_rev};
         }
         return $ref->{rows}->[0]->{value};
      }
   }
   else {
      # error in request
      my ($message, $code) = $tx->error;
      die($message);
   }
}

sub get_service {
   my ($self, $service, %option) = @_;
   
   my $couch_db = $self->_db;
   my $tx = $self->_ua->post("$couch_db/_design/all/_view/services",
                              { "Content-Type" => "application/json" },
                              '{ "keys": ["'.$service.'"] }');

   if (my $res = $tx->success) {
      my $ref = $self->_json->decode($res->body);
      if(scalar(@{ $ref->{rows} }) == 0) {
         return undef;
      }
      else {
         if(! exists $option{full}) {
            delete $ref->{rows}->[0]->{value}->{_id};
            delete $ref->{rows}->[0]->{value}->{_rev};
         }
         return $ref->{rows}->[0]->{value};
      }
   }
   else {
      # error in request
      my ($message, $code) = $tx->error;
      die($message);
   }
}

sub add_server {
   my ($self, $data) = @_;

   $data->{type} = "server";
   $data->{service} ||= [];

   my $uuid = $self->_uuid;
   my $couch_db = $self->_db;
   my $tx = $self->_ua->put("$couch_db/\L$uuid" => {"Content-Type" => "application/json" } => $self->_json->encode($data));

    if (my $res = $tx->success) {
      my $ref = $self->_json->decode($res->body);
      if($ref->{ok} == Mojo::JSON->true) {
         return $self->get_server($data->{name});
      }
      else {
         return;
      }
   }
   else {
      # error in request
      my ($message, $code) = $tx->error;
      die($message);
   }
}

sub add_service {
   my ($self, $data) = @_;

   $data->{type} = "service";

   my $uuid = $self->_uuid;
   my $couch_db = $self->_db;
   my $tx = $self->_ua->put("$couch_db/\L$uuid" => {"Content-Type" => "application/json" } => $self->_json->encode($data));

    if (my $res = $tx->success) {
      my $ref = $self->_json->decode($res->body);
      if($ref->{ok} == Mojo::JSON->true) {
         return $self->get_service($data->{name});
      }
      else {
         return;
      }
   }
   else {
      # error in request
      my ($message, $code) = $tx->error;
      die($message);
   }
}

sub delete_server {
   my ($self, $name) = @_;
   my $server = $self->get_server($name, full => 1);

   my $couch_db = $self->_db;
   if($server) {
      my $tx = $self->_ua->delete("$couch_db/" . $server->{_id} . "?rev=" . $server->{_rev});
      my $ref = $self->_json->decode($tx->res->body);

      if(exists $ref->{ok} && $ref->{ok} == Mojo::JSON->true) {
         return {ok => Mojo::JSON->true};
      }
   }

   return {ok => Mojo::JSON->false};
}

sub delete_service {
   my ($self, $name) = @_;
   my $service = $self->get_service($name, full => 1);

   my $couch_db = $self->_db;
   if($service) {
      my $tx = $self->_ua->delete("$couch_db/" . $service->{_id} . "?rev=" . $service->{_rev});
      my $ref = $self->_json->decode($tx->res->body);

      if(exists $ref->{ok} && $ref->{ok} == Mojo::JSON->true) {
         return {ok => Mojo::JSON->true};
      }
   }

   return {ok => Mojo::JSON->false};
}

sub add_service_to_server {
   my ($self, $server, $service) = @_;

   $service = $self->get_service($service, full => 1);
   $server  = $self->get_server($server, full => 1);

   if(exists $server->{service} && ref($server->{service}) eq "ARRAY") {
      $server->{service} = {};
   }
   elsif(exists $server->{service}->{$service->{name}} ) {
      return 304;
   }
   
   for my $section (keys %{ $service->{variables} }) {
      for my $var (keys %{ $service->{variables}->{$section} } ) {
         $server->{service}->{$service->{name}}->{$section}->{variables}->{$var} = $service->{variables}->{$section}->{$var}->{default};
      }
   }

   my $id = $server->{_id};
   my $couch_db = $self->_db;
   my $tx = $self->_ua->put("$couch_db/$id", { "Content-Type" => "application/json" }, $self->_json->encode($server));
   if($tx->success) {
      return $self->get_server($server->{name});
   }
   else {
      return {ok => Mojo::JSON->false};
   }
}

sub remove_service_from_server {
   my ($self, $server, $service) = @_;

   $service = $self->get_service($service, full => 1);
   $server  = $self->get_server($server, full => 1);

   if(! exists $server->{service}) {
      return 304;
   }
   elsif( exists $server->{service} && ! exists $server->{service}->{$service->{name}} ) {
      return 304;
   }

   delete $server->{service}->{$service->{name}};
   
   my $id = $server->{_id};
   my $couch_db = $self->_db;
   my $tx = $self->_ua->put("$couch_db/$id", { "Content-Type" => "application/json" }, $self->_json->encode($server));
   if($tx->success) {
      return $self->get_server($server->{name});
   }
   else {
      return {ok => Mojo::JSON->false};
   }
}

sub configure_service_of_server {
   my ($self, $server, $service, $data) = @_;

   $server  = $self->get_server($server, full => 1);

   if(! exists $server->{service}) {
      return 404;
   }

   if(exists $server->{service} && ! exists $server->{service}->{$service}) {
      return 404;
   }

   my $old_service = $server->{service}->{$service};
   my $new_service = merge($old_service, $data);

   $server->{service}->{$service} = $new_service;

   my $id = $server->{_id};
   my $couch_db = $self->_db;
   my $tx = $self->_ua->put("$couch_db/$id", { "Content-Type" => "application/json" }, $self->_json->encode($server));
   if($tx->success) {
      return $self->get_server($server->{name});
   }
   else {
      return {ok => Mojo::JSON->false};
   }
}

sub add_section_to_server {
   my ($self, $server, $section, $data) = @_;

   $server  = $self->get_server($server, full => 1);

   $server->{$section} = $data;
   my $id = $server->{_id};
   my $couch_db = $self->_db;
   my $tx = $self->_ua->put("$couch_db/$id", { "Content-Type" => "application/json" }, $self->_json->encode($server));

   if($tx->success) {
      return $self->get_server($server->{name});
   }
   else {
      return {ok => Mojo::JSON->false};
   }
}

sub _ua {
   my ($self) = @_;
   my $ua = Mojo::UserAgent->new;

   return $ua;
}

sub _json {
   my ($self) = @_;
   return Mojo::JSON->new;
}

sub _uuid {
   my ($self) = @_;
   my $mt = Data::UUID::MT->new();
   my $uuid = $mt->create_string();
   $uuid =~ s/\-//g;

   return $uuid;
}

sub _db {
   my ($self) = @_;
   return "http://" . $self->{config}->{server} . "/" . $self->{config}->{database};
}

1;
