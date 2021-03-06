use strict;
use warnings;
use File::Spec::Functions qw( catdir updir );
use FindBin               qw( $Bin );
use lib               catdir( $Bin, updir, 'lib' );

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

use_ok 'Class::Usul::Crypt', qw( decrypt encrypt );

my $plain_text            = 'Hello World';
my $args                  = { cipher => 'Twofish2', salt => 'salt' };
my $base64_encrypted_text = encrypt( $args, $plain_text );

is decrypt( $args, $base64_encrypted_text ), $plain_text, 'Default seed';

$base64_encrypted_text = encrypt( undef, $plain_text );

is decrypt( undef, $base64_encrypted_text), $plain_text, 'Default everything';

$base64_encrypted_text = encrypt( 'test', $plain_text );

is decrypt( 'test', $base64_encrypted_text), $plain_text, 'User password';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
