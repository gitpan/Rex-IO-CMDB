package Rex::IO::CMDB::Server;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

use Data::Dumper;

sub post {
   my $self = shift;
   my $ref = $self->req->json;

   my $new_res = $self->cmdb->add_server($ref);

   $self->render_json($new_res, status => 201);
}

sub get {
   my $self = shift;

   my $data = $self->cmdb->get_server($self->stash("name"));
   my $status = 200;

   unless($data) {
      $data = {};
      $status = 404;
   }

   $self->render_json($data, status => $status);
}

sub delete {
   my $self = shift;
   my $data = $self->cmdb->delete_server($self->stash("name"));

   if($data->{ok} == Mojo::JSON->false) {
      $self->render_json($data, status => 404);
   }
   else {
      $self->render_json($data);
   }
}

sub list {
   my $self = shift;
   
   my $data = $self->cmdb->list_servers;
   $self->render_json($data);
}

sub link {
   my  $self = shift;
   
   my $data = $self->req->json;
   my $status = $self->cmdb->add_service_to_server($self->stash("name"), $data->{service});

   if(ref($status)) {
      $self->render_json($status, status => 200);
   }
   else {
      $self->render_json({}, status => $status);
   }
}

sub service_put {
   my $self = shift;

   my $data = $self->req->json;
   my $status = $self->cmdb->configure_service_of_server($self->stash("name"), $self->stash("service"), $data);

   if(ref($status)) {
      $self->render_json($status, status => 200);
   }
   else {
      $self->render_json({}, status => $status);
   }
}

sub unlink {
   my  $self = shift;
   
   my $data = $self->req->json;
   my $status = $self->cmdb->remove_service_from_server($self->stash("name"), $data->{service});

   if(ref($status)) {
      $self->render_json($status, status => 200);
   }
   else {
      $self->render_json({}, status => $status);
   }
}

sub section_put {
   my $self = shift;

   my $data = $self->req->json;
   my $status = $self->cmdb->add_section_to_server($self->stash("name"), $self->stash("section"), $data);

   if(ref($status)) {
      $self->render_json($status, status => 200);
   }
   else {
      $self->render_json({}, status => $status);
   }
}

1;
