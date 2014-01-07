# @(#)$Ident: 16file.t 2014-01-07 08:27 pjf ;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.35.%d', q$Rev: 1 $ =~ /\d+/gmx );
use File::Spec::Functions   qw( catdir catfile updir );
use FindBin                 qw( $Bin );
use lib                 catdir( $Bin, updir, 'lib' );

use Test::More;
use Test::Requires { version => 0.88 };
use Module::Build;

my $notes = {}; my $perl_ver;

BEGIN {
   my $builder = eval { Module::Build->current };
      $builder and $notes = $builder->notes;
      $perl_ver = $notes->{min_perl_version} || 5.008;
}

use Test::Requires "${perl_ver}";
use English qw( -no_match_vars );

{  package Logger;

   sub new   { return bless {}, __PACKAGE__ }
   sub alert { warn '[ALERT] '.$_[ 1 ] }
   sub debug { warn '[DEBUG] '.$_[ 1 ] }
   sub error { warn '[ERROR] '.$_[ 1 ] }
   sub fatal { warn '[ALERT] '.$_[ 1 ] }
   sub info  { warn '[ALERT] '.$_[ 1 ] }
   sub warn  { warn '[WARNING] '.$_[ 1 ] }
}

SKIP: {
   use Class::Usul;
   use Class::Usul::File;

   my $osname = lc $OSNAME;
   my $cu     = Class::Usul->new
      ( config     => {
         appclass  => 'Class::Usul',
         home      => catdir( qw( lib Class Usul ) ),
         localedir => catdir( qw( t locale ) ),
         tempdir   => 't', },
        debug      => 0,
        log        => Logger->new, );

   my $cuf = Class::Usul::File->new( builder => $cu );

   isa_ok $cuf, 'Class::Usul::File'; is $cuf->tempdir, 't',
      'Temporary directory is t';

   my $tf = [ qw( t test.json ) ];

   ok( (grep { m{ driver }msx } $cuf->io( $tf )->getlines)[ 0 ]
       =~ m{ mysql }msx, 'IO can getlines' );

   my $path = $cuf->absolute( [ qw( a b ) ], 'c' );

   like $path, qr{ a . b . c \z }mx, 'Absolute path 1';

   $path = $cuf->absolute( 'a', [ qw( b c ) ] );

   like $path, qr{ a . b . c \z }mx, 'Absolute path 2';

   my $fdcs = $cuf->dataclass_schema->load( $tf );

   is $fdcs->{credentials}->{test}->{driver}, 'mysql',
      'File::Dataclass::Schema can load';

   unlink catfile( qw( t ipc_srlock.lck ) );
   unlink catfile( qw( t ipc_srlock.shm ) );

   is $cuf->status_for( $tf )->{size}, 196,
      'Status for returns correct file size';

   if ($osname ne 'mswin32' and $osname ne 'cygwin') {
      my $symlink = catfile( qw( t symlink ) );

      $cuf->symlink( 't', 'test.json', [ 'symlink' ] );

      ok -e $symlink, 'Creates a symlink'; -e _ and unlink $symlink;
   }

   my $tempfile = $cuf->tempfile;

   ok( $tempfile, 'Returns tempfile' );

   is ref $tempfile->io_handle, 'File::Temp',
      'Tempfile io handle correct class';

   $cuf->io( $tempfile->pathname )->touch;

   ok( -f $tempfile->pathname, 'Touches temporary file' );

   ($osname eq 'mswin32' or $osname eq 'cygwin') and $tempfile->close;

   $cuf->delete_tmp_files;

   ok( ! -f $tempfile->pathname, 'Deletes temporary files' );

   ok $cuf->tempname =~ m{ $PID .{4} }msx, 'Temporary filename correct pattern';

   my $io = $cuf->io( 't' ); my $entry;

   while (defined ($entry = $io->next)) {
      $entry->filename eq '16file.t' and last;
   }

   ok defined $entry && $entry->filename eq '16file.t', 'Directory listing';
}

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End: