# @(#)$Ident: Build.PL 2013-08-26 21:23 pjf ;

use strict;
use warnings;

use Module::Build 0.4004;

sub whimper { print {*STDOUT} $_[ 0 ]."\n"; exit 0 }

my $perl_ver = 5.010001;
my $name     = 'Class-Usul'; $name =~ s{ - }{::}gmx;

$] >= $perl_ver or $ENV{PERL5_CPANPLUS_IS_VERSION}
   or whimper "Minimum required Perl version is ${perl_ver}";

Module::Build->subclass( code => do { local $/; <DATA> } )->new(
  'module_name' => $name,
  'notes'       => { min_perl_version => $perl_ver },
  'build_requires' => {
    'Module::Build' => '0.4004',
    'Test::Deep' => '0.108',
    'Test::Requires' => '0.06',
    'version' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.4004',
    'version' => '0.88'
  },
  'recommends' => {
    'Proc::ProcessTable' => '0.42'
  },
  'requires' => {
    'Class::Inspector' => '1.24',
    'Class::Load' => '0.18',
    'Class::Null' => '2.101420',
    'Crypt::CBC' => '2.30',
    'Crypt::Twofish2' => '1.02',
    'Data::Printer' => '0.35',
    'Data::Record' => '0.02',
    'Date::Format' => '2.24',
    'DateTime::Format::Epoch' => '0.13',
    'Digest::SHA1' => '2.11',
    'Exporter::Tiny' => '0.026',
    'File::DataClass' => 'v0.26.0',
    'File::Gettext' => 'v0.20.0',
    'File::HomeDir' => '0.93',
    'Getopt::Long::Descriptive' => '0.093',
    'IO::Interactive' => 'v0.0.6',
    'IPC::SRLock' => 'v0.16.0',
    'JSON' => '2.50',
    'Log::Handler' => '0.63',
    'Moo' => '1.003',
    'MooX::ClassStash' => '0.005',
    'MooX::Options' => '3.83',
    'Path::Class' => '0.23',
    'Pod::Eventual' => '0.093330',
    'Regexp::Common' => '2010010201',
    'Term::ReadKey' => '2.30',
    'Text::Autoformat' => '1.669002',
    'Time::Zone' => '2.24',
    'Try::Tiny' => '0.18',
    'Type::Tiny' => '0.012',
    'Unexpected' => 'v0.13.0',
    'YAML::Syck' => '1.17',
    'namespace::clean' => '0.23',
    'namespace::sweep' => '0.006',
    'perl' => '5.010001'
  },

)->create_build_script;

exit 0;

__DATA__

sub _normalize_prereqs { # Dynamic config
   my $self = shift; my $p = $self->SUPER::_normalize_prereqs; return $p;
}
