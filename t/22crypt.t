# @(#)$Id: 22crypt.t 289 2013-04-29 15:25:46Z pjf $

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.16.%d', q$Rev: 289 $ =~ /\d+/gmx );
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

use_ok 'Class::Usul::Crypt', qw(decrypt encrypt);

my $plain_text            = 'Hello World';
my $args                  = { cipher => 'Twofish2', salt => 'salt' };
my $base64_encrypted_text = encrypt( $args, $plain_text );

is decrypt( $args, $base64_encrypted_text ), $plain_text, 'Round trips';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
