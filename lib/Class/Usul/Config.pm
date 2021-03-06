package Class::Usul::Config;

use namespace::autoclean;

use Moo;
use Class::Usul::Constants   qw( CONFIG_EXTN DEFAULT_CONFHOME
                                 DEFAULT_ENCODING DEFAULT_L10N_DOMAIN
                                 FALSE LANG NUL PERL_EXTNS PHASE TRUE );
use Class::Usul::File;
use Class::Usul::Functions   qw( app_prefix class2appdir home2appldir
                                 is_arrayref split_on__ split_on_dash
                                 untaint_path );
use Class::Usul::Types       qw( ArrayRef EncodingType HashRef NonEmptySimpleStr
                                 NonZeroPositiveInt PositiveInt Str );
use Config;
use English                  qw( -no_match_vars );
use File::Basename           qw( basename dirname );
use File::DataClass::Types   qw( Directory File Path );
use File::Gettext::Constants qw( LOCALE_DIRS );
use File::Spec::Functions    qw( canonpath catdir catfile
                                 rel2abs rootdir tmpdir );
use Scalar::Util             qw( blessed );

# Public attributes
has 'appclass'  => is => 'ro',   isa => NonEmptySimpleStr, required => TRUE;

has 'appldir'   => is => 'lazy', isa => Directory,
   coerce       => Directory->coercion;

has 'binsdir'   => is => 'lazy', isa => Path, coerce => Path->coercion;

has 'cfgfiles'  => is => 'lazy', isa => ArrayRef[NonEmptySimpleStr],
   builder      => sub { [] };

has 'ctlfile'   => is => 'lazy', isa => Path, coerce => Path->coercion;

has 'ctrldir'   => is => 'lazy', isa => Path, coerce => Path->coercion;

has 'encoding'  => is => 'ro',   isa => EncodingType,
   coerce       => EncodingType->coercion, default => DEFAULT_ENCODING;

has 'extension' => is => 'lazy', isa => NonEmptySimpleStr,
   default      => CONFIG_EXTN;

has 'home'      => is => 'lazy', isa => Directory,
   coerce       => Directory->coercion, default => DEFAULT_CONFHOME;

has 'locale'    => is => 'ro',   isa => NonEmptySimpleStr, default => LANG;

has 'localedir' => is => 'lazy', isa => Directory,
   coerce       => Directory->coercion;

has 'locales'   => is => 'ro',   isa => ArrayRef[NonEmptySimpleStr],
   builder      => sub { [ LANG ] };

has 'logfile'   => is => 'lazy', isa => Path, coerce => Path->coercion;

has 'logsdir'   => is => 'lazy', isa => Directory,
   coerce       => Directory->coercion;

has 'name'      => is => 'lazy', isa => NonEmptySimpleStr;

has 'no_thrash' => is => 'ro',   isa => NonZeroPositiveInt, default => 3;

has 'phase'     => is => 'lazy', isa => PositiveInt;

has 'prefix'    => is => 'lazy', isa => NonEmptySimpleStr;

has 'pathname'  => is => 'lazy', isa => File, coerce => File->coercion;

has 'root'      => is => 'lazy', isa => Path, coerce => Path->coercion;

has 'rundir'    => is => 'lazy', isa => Path, coerce => Path->coercion;

has 'salt'      => is => 'lazy', isa => NonEmptySimpleStr,
   builder      => sub { $_[ 0 ]->_inflate_symbol( $_[ 1 ], 'prefix' ) };

has 'sessdir'   => is => 'lazy', isa => Path, coerce => Path->coercion;

has 'sharedir'  => is => 'lazy', isa => Path, coerce => Path->coercion;

has 'shell'     => is => 'lazy', isa => File, coerce => File->coercion;

has 'suid'      => is => 'lazy', isa => Path, coerce => Path->coercion;

has 'tempdir'   => is => 'lazy', isa => Directory,
   coerce       => Directory->coercion;

has 'vardir'    => is => 'lazy', isa => Path, coerce => Path->coercion;

has 'l10n_attributes' => is => 'lazy', isa => HashRef,
   builder            => sub { {
      domains         => [ DEFAULT_L10N_DOMAIN, $_[ 0 ]->name ] } };

has 'lock_attributes' => is => 'ro',   isa => HashRef, builder => sub { {} };

has 'log_attributes'  => is => 'ro',   isa => HashRef, builder => sub { {} };

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $class, @args) = @_; my $attr = $orig->( $class, @args );

   my $paths; if ($paths = $attr->{cfgfiles} and $paths->[ 0 ]) {
      my $loaded = Class::Usul::File->data_load( paths => $paths ) || {};

      $attr = { %{ $attr }, %{ $loaded } };
   }

   for my $name (keys %{ $attr }) {
      defined $attr->{ $name }
          and $attr->{ $name } =~ m{ \A __([^\(]+?)__ \z }mx
          and $attr->{ $name } = $class->_inflate_symbol( $attr, $1 );
   }

   $class->inflate_paths( $attr );

   return $attr;
};

# Public methods
sub canonicalise {
   my ($self, $base, $relpath) = @_;

   my @base = ((is_arrayref $base) ? @{ $base } : $base);
   my @rest = split m{ / }mx, $relpath;
   my $path = canonpath( untaint_path catdir( @base, @rest ) );

   -d $path and return $path;

   return canonpath( untaint_path catfile( @base, @rest ) );
}

sub inflate_paths {
   my ($class, $attr) = @_;

   for my $name (keys %{ $attr }) {
      defined $attr->{ $name }
          and $attr->{ $name } =~ m{ \A __(.+?)\((.+?)\)__ \z }mx
          and $attr->{ $name } = $class->_inflate_path( $attr, $1, $2 );
   }

   return;
}

# Private methods
sub _build_appldir {
   my ($self, $appclass, $home) = __unpack( @_ ); my $dir;

   if ($dir = home2appldir $home) {
      $dir = rel2abs( untaint_path( $dir ) );
      -d catdir( $dir, 'lib' ) and return $dir;
   }

   $dir = catdir ( NUL, 'var', class2appdir $appclass );
   $dir = rel2abs( untaint_path( $dir    ) ); -d $dir and return $dir;
   $dir = rel2abs( untaint_path( $home   ) ); -d $dir and return $dir;
   return rel2abs( untaint_path( rootdir ) );
}

sub _build_binsdir {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw( appldir bin ) );

   return -d $dir ? $dir : untaint_path $Config{installsitescript};
}

sub _build_ctlfile {
   my $name      = $_[ 0 ]->_inflate_symbol( $_[ 1 ], 'name'      );
   my $extension = $_[ 0 ]->_inflate_symbol( $_[ 1 ], 'extension' );

   return $_[ 0 ]->_inflate_path( $_[ 1 ], 'ctrldir', $name.$extension );
}

sub _build_ctrldir {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw( vardir etc ) );

   -d $dir and return $dir;

   $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw( appldir etc ) );

   -d $dir and return $dir;

   return [ NUL, qw( usr local etc ) ];
}

sub _build_localedir {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw( vardir locale ) );

   -d $dir and return $dir;

   for (map { catdir( @{ $_ } ) } @{ LOCALE_DIRS() } ) { -d $_ and return $_ }

   return $_[ 0 ]->_inflate_path( $_[ 1 ], 'tempdir' );
}

sub _build_logfile {
   my $name = $_[ 0 ]->_inflate_symbol( $_[ 1 ], 'name' );

   return $_[ 0 ]->_inflate_path( $_[ 1 ], 'logsdir', "${name}.log" );
}

sub _build_logsdir {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw( vardir logs ) );

   return -d $dir ? $dir : $_[ 0 ]->_inflate_path( $_[ 1 ], 'tempdir' );
}

sub _build_name {
   my $name = basename(   $_[ 0 ]->_inflate_path
                        ( $_[ 1 ], 'pathname' ), PERL_EXTNS );

   return (split_on__ $name, 1) || (split_on_dash $name, 1) || $name;
}

sub _build_pathname {
   my $name = ('-' eq substr $PROGRAM_NAME, 0, 1) ? $EXECUTABLE_NAME
                                                  : $PROGRAM_NAME;

   return rel2abs( (split m{ [ ][\-][ ] }mx, $name)[ 0 ] );
}

sub _build_phase {
   my $verdir  = basename( $_[ 0 ]->_inflate_path( $_[ 1 ], 'appldir' ) );
   my ($phase) = $verdir =~ m{ \A v \d+ \. \d+ p (\d+) \z }msx;

   return defined $phase ? $phase : PHASE;
}

sub _build_prefix {
   my $appclass = $_[ 0 ]->_inflate_symbol( $_[ 1 ], 'appclass' );

   return (split m{ :: }mx, lc $appclass)[ -1 ];
}

sub _build_root {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw( vardir root ) );

   return -d $dir ? $dir : $_[ 0 ]->_inflate_path( $_[ 1 ], 'vardir' );
}

sub _build_rundir {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw( vardir run ) );

   return -d $dir ? $dir : $_[ 0 ]->_inflate_path( $_[ 1 ], 'vardir' );
}

sub _build_sessdir {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw( vardir hist ) );

   return -d $dir ? $dir : $_[ 0 ]->_inflate_path( $_[ 1 ], 'vardir' );
}

sub _build_sharedir {
   my $dir =  $_[ 0 ]->_inflate_path( $_[ 1 ], qw( vardir share ) );

   return -d $dir ? $dir : $_[ 0 ]->_inflate_path( $_[ 1 ], 'vardir' );
}

sub _build_shell {
   my $file = $ENV{SHELL};                    -e $file and return $file;
      $file = catfile( NUL, qw( bin ksh ) );  -e $file and return $file;
      $file = catfile( NUL, qw( bin bash ) ); -e $file and return $file;
   return     catfile( NUL, qw( bin sh ) );
}

sub _build_suid {
   my $prefix = $_[ 0 ]->_inflate_symbol( $_[ 1 ], 'prefix' );

   return $_[ 0 ]->_inflate_path( $_[ 1 ], 'binsdir', "${prefix}_admin" );
}

sub _build_tempdir {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw( vardir tmp ) );

   return -d $dir ? $dir : untaint_path tmpdir;
}

sub _build_vardir {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw( appldir var ) );

   return -d $dir ? $dir : $_[ 0 ]->_inflate_path( $_[ 1 ], 'appldir' );
}

sub _inflate_path {
   my ($self, $attr, $symbol, $relpath) = @_; $attr ||= {};

   my $inflated = $self->_inflate_symbol( $attr, $symbol );

   $relpath or return canonpath( untaint_path $inflated );

   return $self->canonicalise( $inflated, $relpath );
}

sub _inflate_symbol {
   my ($self, $attr, $symbol) = @_; $attr ||= {};

   my $attr_name = lc $symbol; my $method = "_build_${attr_name}";

   return blessed $self                      ? $self->$attr_name()
        : __is_inflated( $attr, $attr_name ) ? $attr->{ $attr_name }
                                             : $self->$method( $attr );
}

# Private functions
sub __is_inflated {
   my ($attr, $attr_name) = @_;

   return exists $attr->{ $attr_name } && defined $attr->{ $attr_name }
       && $attr->{ $attr_name } !~ m{ \A __ }mx ? TRUE : FALSE;
}

sub __unpack {
   my ($self, $attr) = @_; $attr ||= {};

   blessed $self and return ($self, $self->{appclass}, $self->{home});

   return ($self, $attr->{appclass}, $attr->{home});
}

1;

__END__

=pod

=head1 Name

Class::Usul::Config - Inflate config values

=head1 Synopsis

   use Class::Usul::Config;

=head1 Description

Defines the following list of attributes

=over 3

=item C<appclass>

Required string. The classname of the application for which this is the
configuration class

=item C<appldir>

Directory. Defaults to the application's install directory

=item C<binsdir>

Directory. Defaults to the application's I<bin> directory

=item C<cfgfiles>

An array reference of non empty simple strings. The list of configuration
files to load when instantiating an instance of the configuration class

=item C<ctlfile>

File in the C<ctrldir> directory that contains this programs control data

=item C<ctrldir>

Directory containing the per program configuration files

=item C<encoding>

String default to the constant I<DEFAULT_ENCODING>

=item C<extension>

String defaults to the constant I<CONFIG_EXTN>

=item C<home>

Directory containing the config file. Required

=item C<l10n_attributes>

Hash ref of attributes used to construct a L<Class::Usul::L10N>
object. By default contains one key, C<domains>, an array reference
which defaults to the constant C<DEFAULT_L10N_DOMAIN> and the
applications configuration name. The filename(s) used to translate
messages into different languages

=item C<locale>

The locale for language translation of text. Defaults to the constant
C<LANG>

=item C<localedir>

Directory containing the GNU Gettext portable object files used to translate
messages into different languages

=item C<locales>

Array reference containing the list of supported locales. The default list
contains only the constant C<LANG>

=item C<lock_attributes>

Hash ref of attributes used to construct an L<IPC::SRLock> object

=item C<log_attributes>

Hash ref of attributes used to construct a L<Class::Usul::Log> object

=item C<logfile>

File in the C<logsdir> to which this program will log

=item C<logsdir>

Directory containing the application log files

=item C<name>

String. Name of the program

=item C<no_thrash>

Integer default to 3. Number of seconds to sleep in a polling loop to
avoid processor thrash

=item C<pathname>

File defaults to the absolute path to the I<PROGRAM_NAME> system constant

=item C<phase>

Integer. Phase number indicates the type of install, e.g. 1 live, 2 test,
3 development

=item C<prefix>

String. Program prefix

=item C<root>

Directory. Path to the web applications document root

=item C<rundir>

Directory. Contains a running programs PID file

=item C<salt>

String. This applications salt for passwords as set by the administrators . It
is used to perturb the encryption methods. Defaults to the I<prefix>
attribute value

=item C<sessdir>

Directory. The session directory

=item C<sharedir>

Directory containing assets used by the application

=item C<shell>

File. The default shell used to create new OS users

=item C<suid>

File. Name of the setuid root program in the I<bin> directory. Defaults to
the I<prefix>_admin

=item C<tempdir>

Directory. It is the location of any temporary files created by the
application. Defaults to the L<File::Spec> tempdir

=item C<vardir>

Directory. Contains all of the non program code directories

=back

=head1 Subroutines/Methods

=head2 BUILDARGS

Loads the configuration files if specified. Calls L</inflate_symbol>
and L</inflate_path>

=head2 canonicalise

   $untainted_canonpath = $self->canonicalise( $base, $relpath );

Appends C<$relpath> to C<$base> using L<File::Spec::Functions>. The C<$base>
argument can be an array ref or a scalar. The C<$relpath> argument must be
separated by slashes. The return path is untainted and canonicalised

=head2 inflate_paths

Calls L</_inflate_path> for each of the matching values in the hash that
was passed as argument

=head2 _inflate_path

Inflates the I<__symbol( relative_path )__> values to their actual runtime
values

=head2 _inflate_symbol

Inflates the I<__SYMBOL__> values to their actual runtime values

=head1 Configuration and Environment

None

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul::File>

=item L<Moo>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2014 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
