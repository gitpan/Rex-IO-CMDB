use Mojo::Base -strict;

use Test::More tests => 2;
use Test::Mojo;

# create a tmp conf file
open(my $fh, ">", "cmdb.conf");
print $fh "{ server => 'localhost:5984', database => 'cmdb' }";
close($fh);

my $t = Test::Mojo->new('Rex::IO::CMDB');
$t->get_ok('/')->status_is(404);
