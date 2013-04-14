# @(#)$Id: Config.pm 270 2013-04-14 18:38:18Z pjf $

package Class::Usul::Config;

use version; our $VERSION = qv( sprintf '0.13.%d', q$Rev: 270 $ =~ /\d+/gmx );

use Class::Usul::File;
use Class::Usul::Moose;
use Class::Usul::Constants;
use Class::Usul::Functions       qw(app_prefix class2appdir home2appldir
                                    is_arrayref split_on__ split_on_dash
                                    untaint_path);
use Config;
use English                      qw(-no_match_vars);
use File::Basename               qw(basename dirname);
use File::DataClass::Constraints qw(Directory File Path);
use File::Gettext::Constants;
use File::Spec::Functions        qw(canonpath catdir catfile rel2abs rootdir
                                    tmpdir);

has 'appclass'        => is => 'ro',   isa => NonEmptySimpleStr,
   required           => TRUE;

has 'encoding'        => is => 'ro',   isa => EncodingType, coerce => TRUE,
   default            => DEFAULT_ENCODING;

has 'home'            => is => 'ro',   isa => Directory, coerce => TRUE,
   documentation      => 'Directory containing the config file',
   required           => TRUE;

has 'l10n_attributes' => is => 'ro',   isa => HashRef, default => sub { {} };

has 'lock_attributes' => is => 'ro',   isa => HashRef, default => sub { {} };

has 'log_attributes'  => is => 'ro',   isa => HashRef, default => sub { {} };

has 'no_thrash'       => is => 'ro',   isa => PositiveInt, default => 3;


has 'appldir'         => is => 'lazy', isa => Directory, coerce => TRUE;

has 'binsdir'         => is => 'lazy', isa => Path,      coerce => TRUE;

has 'ctlfile'         => is => 'lazy', isa => Path,      coerce => TRUE;

has 'ctrldir'         => is => 'lazy', isa => Path,      coerce => TRUE;

has 'dbasedir'        => is => 'lazy', isa => Path,      coerce => TRUE;

has 'localedir'       => is => 'lazy', isa => Directory, coerce => TRUE;

has 'logfile'         => is => 'lazy', isa => Path,      coerce => TRUE;

has 'logsdir'         => is => 'lazy', isa => Directory, coerce => TRUE;

has 'pathname'        => is => 'lazy', isa => File,      coerce => TRUE;

has 'root'            => is => 'lazy', isa => Path,      coerce => TRUE;

has 'rundir'          => is => 'lazy', isa => Path,      coerce => TRUE;

has 'sessdir'         => is => 'lazy', isa => Path,      coerce => TRUE;

has 'shell'           => is => 'lazy', isa => File,      coerce => TRUE;

has 'suid'            => is => 'lazy', isa => Path,      coerce => TRUE;

has 'tempdir'         => is => 'lazy', isa => Directory, coerce => TRUE;

has 'vardir'          => is => 'lazy', isa => Path,      coerce => TRUE;


has 'extension'       => is => 'lazy', isa => NonEmptySimpleStr;

has 'name'            => is => 'lazy', isa => NonEmptySimpleStr;

has 'phase'           => is => 'lazy', isa => PositiveInt;

has 'prefix'          => is => 'lazy', isa => NonEmptySimpleStr;

has 'salt'            => is => 'lazy', isa => NonEmptySimpleStr;

around 'BUILDARGS' => sub {
   my ($next, $class, @args) = @_; my $attr = $class->$next( @args ); my $paths;

   if ($paths = delete $attr->{cfgfiles} and $paths->[ 0 ]) {
      my $loaded = Class::Usul::File->data_load( paths => $paths );

      $attr = { %{ $loaded || {} }, %{ $attr } };
   }

   for my $attr_name (keys %{ $attr }) {
      defined $attr->{ $attr_name }
          and $attr->{ $attr_name } =~ m{ \A __([^\(]+?)__ \z }mx
          and $attr->{ $attr_name } = $class->_inflate_symbol( $attr, $1 );
   }

   for my $attr_name (keys %{ $attr }) {
      defined $attr->{ $attr_name }
          and $attr->{ $attr_name } =~ m{ \A __(.+?)\((.+?)\)__ \z }mx
          and $attr->{ $attr_name } = $class->_inflate_path( $attr, $1, $2 );
   }

   return $attr;
};

sub canonicalise {
   my ($self, $base, $relpath) = @_;

   my @base = ((is_arrayref $base) ? @{ $base } : $base);
   my @rest = split m{ / }mx, $relpath;
   my $path = canonpath( untaint_path catdir( @base, @rest ) );

   -d $path and return $path;

   return canonpath( untaint_path catfile( @base, @rest ) );
}

# Private methods

sub _build_appldir {
   my ($self, $appclass, $home) = __unpack( @_ ); my $dir = home2appldir $home;

   ($dir and -d catdir( $dir, q(bin) ))
      or $dir = catdir( NUL, q(var), (class2appdir $appclass) );

   -d $dir or $dir = $home;

   return rel2abs( untaint_path ($dir || rootdir) );
}

sub _build_binsdir {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw(appldir bin) );

   return -d $dir ? $dir : untaint_path $Config{installsitescript};
}

sub _build_ctlfile {
   my $name      = $_[ 0 ]->_inflate_symbol( $_[ 1 ], q(name)      );
   my $extension = $_[ 0 ]->_inflate_symbol( $_[ 1 ], q(extension) );

   return $_[ 0 ]->_inflate_path( $_[ 1 ], q(ctrldir), $name.$extension );
}

sub _build_ctrldir {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw(vardir etc) );

   return -d $dir ? $dir : $_[ 0 ]->_inflate_path( $_[ 1 ], qw(appldir etc) );
}

sub _build_dbasedir {
   my $dir =  $_[ 0 ]->_inflate_path( $_[ 1 ], qw(vardir db) );

   return -d $dir ? $dir : $_[ 0 ]->_inflate_path( $_[ 1 ], q(vardir) );
}

sub _build_extension {
   return CONFIG_EXTN;
}

sub _build_localedir {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw(vardir locale) );

   -d $dir and return $dir;

   for (map { catdir( @{ $_ } ) } @{ DIRECTORIES() } ) { -d $_ and return $_ }

   return $_[ 0 ]->_inflate_path( $_[ 1 ], qw(tempdir) );
}

sub _build_logfile {
   my $name = $_[ 0 ]->_inflate_symbol( $_[ 1 ], q(name) );

   return $_[ 0 ]->_inflate_path( $_[ 1 ], q(logsdir), "${name}.log" );
}

sub _build_logsdir {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw(vardir logs) );

   return -d $dir ? $dir : $_[ 0 ]->_inflate_path( $_[ 1 ], qw(tempdir) );
}

sub _build_name {
   my $name = basename( $_[ 0 ]->_inflate_path( $_[ 1 ], q(pathname) ), EXTNS );

   return (split_on__ $name, 1) || (split_on_dash $name, 1) || $name;
}

sub _build_pathname {
   return rel2abs( (q(-) eq substr $PROGRAM_NAME, 0, 1) ? $EXECUTABLE_NAME
                                                        : $PROGRAM_NAME );
}

sub _build_path_to {
   my ($self, $appclass, $home) = __unpack( @_ ); return $home;
}

sub _build_phase {
   my $verdir  = basename( $_[ 0 ]->_inflate_path( $_[ 1 ], q(appldir) ) );
   my ($phase) = $verdir =~ m{ \A v \d+ \. \d+ p (\d+) \z }msx;

   return defined $phase ? $phase : PHASE;
}

sub _build_prefix {
   my $appclass = $_[ 0 ]->_inflate_symbol( $_[ 1 ], q(appclass) );

   return (split m{ :: }mx, lc $appclass)[ -1 ];
}

sub _build_root {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw(vardir root) );

   return -d $dir ? $dir : $_[ 0 ]->_inflate_path( $_[ 1 ], q(vardir) );
}

sub _build_rundir {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw(vardir run) );

   return -d $dir ? $dir : $_[ 0 ]->_inflate_path( $_[ 1 ], q(vardir) );
}

sub _build_salt {
   return $_[ 0 ]->_inflate_symbol( $_[ 1 ], q(prefix) );
}

sub _build_sessdir {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw(vardir hist) );

   return -d $dir ? $dir : $_[ 0 ]->inflate_path( $_[ 1 ], q(vardir) );
}

sub _build_shell {
   my $file = catfile( NUL, qw(bin ksh) ); -f $file and return $file;

   $file = $ENV{SHELL}; -f $file and return $file;

   return catfile( NUL, qw(bin sh) );
}

sub _build_suid {
   my $prefix = $_[ 0 ]->_inflate_symbol( $_[ 1 ], q(prefix) );

   return $_[ 0 ]->_inflate_path( $_[ 1 ], q(binsdir), "${prefix}_admin" );
}

sub _build_tempdir {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw(vardir tmp) );

   return -d $dir ? $dir : untaint_path tmpdir;
}

sub _build_vardir {
   my $dir = $_[ 0 ]->_inflate_path( $_[ 1 ], qw(appldir var) );

   return -d $dir ? $dir : $_[ 0 ]->_inflate_path( $_[ 1 ], q(appldir) );
}

sub _inflate_path {
   my ($self, $attr, $symbol, $relpath) = @_; $attr ||= {};

   my $inflated = $self->_inflate_symbol( $attr, $symbol );

   $relpath or return canonpath( untaint_path $inflated );

   return $self->canonicalise( $inflated, $relpath );
}

sub _inflate_symbol {
   my ($self, $attr, $symbol) = @_; $attr ||= {};

   my $attr_name = lc $symbol; my $method = q(_build_).$attr_name;

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

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 Name

Class::Usul::Config - Inflate config values

=head1 Version

Describes Class::Usul::Config version 0.13.$Revision: 270 $

=head1 Synopsis

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

=item C<ctlfile>

File in the C<ctrldir> directory that contains this programs control data

=item C<ctrldir>

Directory containing the per program configuration files

=item C<dbasedir>

Directory containing the data file used to create the applications database

=item C<encoding>

String default to the constant I<DEFAULT_ENCODING>

=item C<extension>

String defaults to the constant I<CONFIG_EXTN>

=item C<home>

Directory containing the config file. Required

=item C<l10n_attributes>

Hash ref of attributes used to construct a L<Class::Usul::L10N> object

=item C<localedir>

Directory containing the GNU Gettext portable object files used to translate
messages into different languages

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

=item L<Class::Usul::Moose>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <Support at RoxSoft.co.uk> >>

=head1 License and Copyright

Copyright (c) 2013 Peter Flanigan. All rights reserved

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
