package Rex::IO::CMDB::Service;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

sub post {
   my $self = shift;
   my $ref = $self->req->json;

   my $new_res = $self->cmdb->add_service($ref);

   $self->render_json($new_res, status => 201);
}

sub get {
   my $self = shift;

   my $data = $self->cmdb->get_service($self->stash("name"));
   my $status = 200;

   unless($data) {
      $data = {};
      $status = 404;
   }

   $self->render_json($data, status => $status);
}

sub delete {
   my $self = shift;
   my $data = $self->cmdb->delete_service($self->stash("name"));
   $self->render_json($data);
}

sub list {
   my $self = shift;
   
   my $data = $self->cmdb->list_services;
   $self->render_json($data);
}

sub link {
   my  $self = shift;
   
   my $data = $self->req->json;
   my $status = $self->cmdb->add_service_to_server($data->{server}, $self->stash("name"));

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
   my $status = $self->cmdb->remove_service_from_server($data->{server}, $self->stash("name"));

   if(ref($status)) {
      $self->render_json($status, status => 200);
   }
   else {
      $self->render_json({}, status => $status);
   }
}

1;
