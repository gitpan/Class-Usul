use strict;
use warnings;

use Module::Build 0.4004;

sub whimper { print {*STDOUT} $_[ 0 ]."\n"; exit 0 }

my $perl_ver = 5.010001;
my $name     = 'Class-Usul'; $name =~ s{ - }{::}gmx;
my $prereqs  = {
  'build_requires' => {
    'Capture::Tiny' => '0.22',
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
    'IPC::Run' => '0.89',
    'Proc::ProcessTable' => '0.42'
  },
  'requires' => {
    'Class::Inspector' => '1.28',
    'Class::Null' => '2.101420',
    'Crypt::CBC' => '2.30',
    'Crypt::Twofish2' => '1.02',
    'Data::Printer' => '0.35',
    'Data::Record' => '0.02',
    'Date::Format' => '2.24',
    'DateTime::Format::Epoch' => '0.13',
    'Exporter::Tiny' => '0.026',
    'File::DataClass' => 'v0.35.0',
    'File::Gettext' => 'v0.22.0',
    'File::HomeDir' => '0.93',
    'Getopt::Long::Descriptive' => '0.093',
    'IO::Interactive' => 'v0.0.6',
    'IPC::SRLock' => 'v0.21.0',
    'JSON::MaybeXS' => '1.001000',
    'Log::Handler' => '0.63',
    'Module::Runtime' => '0.013',
    'Moo' => '1.004002',
    'MooX::ClassStash' => '0.005',
    'Path::Class' => '0.32',
    'Pod::Eventual' => '0.093330',
    'Regexp::Common' => '2010010201',
    'Sub::Install' => '0.925',
    'Term::ReadKey' => '2.30',
    'Text::Autoformat' => '1.669002',
    'Time::Zone' => '2.24',
    'Try::Tiny' => '0.18',
    'Type::Tiny' => '0.030',
    'Unexpected' => 'v0.22.0',
    'namespace::clean' => '0.24',
    'namespace::sweep' => '0.006',
    'perl' => '5.010001'
  },
};

if ($] < $perl_ver) {
   $ENV{AUTOMATED_TESTING}
      or $ENV{PERL_CPAN_REPORTER_CONFIG}
      or $ENV{PERL5_CPANPLUS_IS_VERSION}
      or whimper "Minimum required Perl version is ${perl_ver}";
   $prereqs->{build_requires} = { %{ $prereqs->{configure_requires} } };
   $prereqs->{build_requires}->{ 'Test::Requires' } = 0.06;
   delete $prereqs->{requires};
}

Module::Build->new(
  'module_name' => $name,
  'notes'       => { min_perl_version => $perl_ver },
  %{ $prereqs },

)->create_build_script;

exit 0;
