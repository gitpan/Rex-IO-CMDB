#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
=head1 Rex::IO::CMDB - Configuration Management Database

This is a simple Database holding information about services and servers.

=head1 GETTING HELP

=over 4

=item * IRC: irc.freenode.net #rex

=item * Bug Tracker: L<https://github.com/krimdomu/rex-io-cmdb/issues>

=back

=head1 INSTALLATION

First you have to install CouchDB from http://couchdb.apache.org/. There are already some Linux Distributions that ships CouchDB.

=over 4

=item Gentoo

 echo "dev-db/couchdb ~amd64" >>/etc/portage/package.accept_keywords
 emerge dev-db/couchdb

=item Ubuntu

 apt-get install couchdb

=item Fedora

 yum install couchdb

=item From Source

You can also install it from source. You can download the sourcecode from http://couchdb.apache.org/

=back

Than you can install Rex::IO::CMDB. For example with cpanminus:

 cpanm Rex::IO::CMDB

After installing create the file I</etc/rex/io/cmdb.conf>. And set the url to Rex::IO::CMDB.

 {
    # set the couchdb server and port
    server => "localhost:5984",

    # set the database name
    database => "cmdb",
 }

Now it is time to initialize the database:

 rex_iocmdb_initdb --server=localhost:5984 --db-name=cmdb

And start the server:

 rex_iocmdb daemon

You can also define an other Listen Port (default is 3000)

 rex_iocmdb daemon -l 'http://:4000'

=cut


package Rex::IO::CMDB;
use Mojo::Base 'Mojolicious';

our $VERSION = "0.0.2";

# This method will run once at server start
sub startup {
   my $self = shift;

   # Documentation browser under "/perldoc"
   $self->plugin("PODRenderer");


   my @cfg = ("/etc/rex/io/cmdb.conf", "/usr/local/etc/rex/io/cmdb.conf", "cmdb.conf");
   my $cfg;
   for my $file (@cfg) {
      if(-f $file) {
         $cfg = $file;
         last;
      }
   }

   unless($cfg) {
      print "No configuration file found.\n";
      print "Please create a configuration file in one of the following locations:\n";
      print " * " . join("\n * ", @cfg);
      print "\n";

      exit 1;
   }

   $self->plugin('Config', file => $cfg);
   $self->plugin("Rex::IO::CMDB::Mojolicious::Plugin::CMDB");

   # Router
   my $r = $self->routes;

   $r->delete("/server/:name")->to("server#delete");
   $r->delete("/service/:name")->to("service#delete");

   $r->post("/server")->to("server#post");
   $r->post("/service")->to("service#post");

   $r->get("/server/:name")->to("server#get");
   $r->get("/service/:name")->to("service#get");

   $r->route("/server")->via("LIST")->to("server#list");
   $r->route("/service")->via("LIST")->to("service#list");

   # link service/server to server/service
   $r->route("/service/:name")->via("LINK")->to("service#link");
   $r->route("/server/:name")->via("LINK")->to("server#link");

   $r->route("/server/:name")->via("UNLINK")->to("server#unlink");
   $r->route("/service/:name")->via("UNLINK")->to("service#unlink");

   $r->put("/server/:name/service/:service")->to("server#service_put");

   $r->put("/server/:name/:section")->to("server#section_put");

}

1;
