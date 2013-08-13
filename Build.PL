# @(#)$Ident: Build.PL 2013-08-13 22:31 pjf ;

use strict;
use warnings;

use Module::Build;

sub whimper { print {*STDOUT} $_[ 0 ]."\n"; exit 0 }

$] >= 5.01 or whimper "Minimum required Perl version is 5.01";

my $code = do { local $/; <DATA> };

Module::Build->subclass( code => $code )->new(
  'module_name' => 'Class::Usul',
  'notes'       => { min_perl_version => 5.01 },
  'build_requires' => {
    'Module::Build' => '0.4004',
    'Test::Deep' => '0.108',
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
    'File::DataClass' => 'v0.22.0',
    'File::Gettext' => 'v0.19.0',
    'File::HomeDir' => '0.93',
    'Getopt::Long::Descriptive' => '0.093',
    'IO::Interactive' => 'v0.0.6',
    'IPC::SRLock' => 'v0.12.0',
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
    'Try::Tiny' => '0.09',
    'Type::Tiny' => '0.012',
    'Unexpected' => 'v0.6.0',
    'YAML::Syck' => '1.17',
    'namespace::clean' => '0.23',
    'namespace::sweep' => '0.006'
  },

)->create_build_script;

exit 0;

__DATA__

sub _normalize_prereqs { # Dynamic config
   my $self = shift; my $p = $self->SUPER::_normalize_prereqs; return $p;
}
