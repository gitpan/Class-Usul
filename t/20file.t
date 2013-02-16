# @(#)$Id: 20file.t 248 2013-02-13 23:17:39Z pjf $

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.12.%d', q$Rev: 248 $ =~ /\d+/gmx );
use File::Spec::Functions;
use FindBin qw( $Bin );
use lib catdir( $Bin, updir, q(lib) );

use Module::Build;
use Test::More;

BEGIN {
   my $current = eval { Module::Build->current };

   $current and $current->notes->{stop_tests}
            and plan skip_all => $current->notes->{stop_tests};
}

use Class::Null;
use English qw( -no_match_vars );
use Exception::Class ( q(TestException) => { fields => [ qw(arg1 arg2) ] } );

{  package Logger;

   sub new   { return bless {}, __PACKAGE__ }
   sub alert { warn '[ALERT] '.$_[ 1 ] }
   sub debug { warn '[DEBUG] '.$_[ 1 ] }
   sub error { warn '[ERROR] '.$_[ 1 ] }
   sub fatal { warn '[ALERT] '.$_[ 1 ] }
   sub info  { warn '[ALERT] '.$_[ 1 ] }
   sub warn  { warn '[WARNING] '.$_[ 1 ] }
}

use Class::Usul;
use Class::Usul::File;

my $osname = lc $OSNAME;
my $cu     = Class::Usul->new
   ( config       => {
      appclass  => q(Class::Usul),
      home      => catdir( qw(lib Class Usul) ),
      localedir => catdir( qw(t locale) ),
      tempdir   => q(t), },
     debug        => 0,
     log          => Logger->new, );

my $cuf = Class::Usul::File->new( builder => $cu );

isa_ok $cuf, 'Class::Usul::File'; is $cuf->tempdir, q(t),
   'Temporary directory is t';

my $tf = [ qw(t test.xml) ];

ok( (grep { m{ name }msx } $cuf->io( $tf )->getlines)[ 0 ] =~ m{ library }msx,
    'IO can getlines' );

my $path = $cuf->absolute( [ qw(test test) ], q(test) );

like $path, qr{ test . test . test \z }mx, 'Absolute path 1';

$path = $cuf->absolute( q(test), q(test) );

like $path, qr{ test . test \z }mx, 'Absolute path 2';

my $fdcs = $cuf->dataclass_schema->load( $tf );

is $fdcs->{credentials}->{library}->{driver}, q(mysql),
   'File::Dataclass::Schema can load';

unlink catfile( qw(t ipc_srlock.lck) );
unlink catfile( qw(t ipc_srlock.shm) );

is $cuf->status_for( $tf )->{size}, 237, 'Status for returns correct file size';

if ($osname ne 'mswin32' and $osname ne 'cygwin') {
   my $symlink = catfile( qw(t symlink) );

   $cuf->symlink( q(t), q(test.xml), [ qw(t symlink) ] );

   ok -e $symlink, 'Creates a symlink'; -e _ and unlink $symlink;
}

my $tempfile = $cuf->tempfile;

ok( $tempfile, 'Returns tempfile' );

is ref $tempfile->io_handle, q(File::Temp), 'Tempfile io handle correct class';

$cuf->io( $tempfile->pathname )->touch;

ok( -f $tempfile->pathname, 'Touches temporary file' );

($osname eq 'mswin32' or $osname eq 'cygwin') and $tempfile->close;

$cuf->delete_tmp_files;

ok( ! -f $tempfile->pathname, 'Deletes temporary files' );

ok $cuf->tempname =~ m{ $PID .{4} }msx, 'Temporary filename correct pattern';

my $io = $cuf->io( q(t) ); my $entry;

while (defined ($entry = $io->next)) {
   $entry->filename eq q(10functions.t) and last;
}

ok defined $entry && $entry->filename eq q(10functions.t), 'Directory listing';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
