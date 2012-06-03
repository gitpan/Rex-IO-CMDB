#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::CMDB::Driver;
   
use strict;
use warnings;
use Data::Dumper;

sub factory {
   my ($class, $driver, $config) = @_;
   

   $driver = "Rex::IO::CMDB::Driver::$driver";
   eval "use $driver";

   if($@) {
      die($@);
   }

   return $driver->new(config => $config);
}

1;
