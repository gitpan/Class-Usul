# @(#)$Id: 03podcoverage.t 277 2013-04-21 20:02:29Z pjf $

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.14.%d', q$Rev: 277 $ =~ /\d+/gmx );
use File::Spec::Functions;
use FindBin qw( $Bin );
use lib catdir( $Bin, updir, q(lib) );

use English qw(-no_match_vars);
use Test::More;

BEGIN {
   if (!-e catfile( $Bin, updir, q(MANIFEST.SKIP) )) {
      plan skip_all => 'POD coverage test only for developers';
   }
}

eval "use Test::Pod::Coverage 1.04";

plan skip_all => 'Test::Pod::Coverage 1.04 required' if ($EVAL_ERROR);

all_pod_coverage_ok();

# Local Variables:
# mode: perl
# tab-width: 3
# End:
