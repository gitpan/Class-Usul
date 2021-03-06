package Class::Usul;

use 5.010001;
use feature 'state';
use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.51.%d', q$Rev: 1 $ =~ /\d+/gmx );

use Moo;
use Class::Usul::Constants  qw( EXCEPTION_CLASS FALSE TRUE );
use Class::Usul::Functions  qw( data_dumper merge_attributes );
use Class::Usul::L10N;
use Class::Usul::Log;
use Class::Usul::Types      qw( Bool ConfigType EncodingType HashRef
                                L10NType LoadableClass LockType LogType );
use IPC::SRLock;

# Public attributes
has 'config'       => is => 'lazy', isa => ConfigType, builder => sub {
   $_[ 0 ]->config_class->new( $_[ 0 ]->_config_attr ) },
   init_arg        => undef;

has '_config_attr' => is => 'ro',   isa => HashRef, builder => sub { {} },
   init_arg        => 'config';

has 'config_class' => is => 'ro',   isa => LoadableClass,
   coerce          => LoadableClass->coercion,
   default         => 'Class::Usul::Config';

has 'debug'        => is => 'lazy', isa => Bool, default => FALSE;

has 'encoding'     => is => 'lazy', isa => EncodingType,
   builder         => sub { $_[ 0 ]->config->encoding };

has 'l10n'         => is => 'lazy', isa => L10NType,
   builder         => sub { Class::Usul::L10N->new( builder => $_[ 0 ] ) },
   handles         => [ 'localize' ];

has 'lock'         => is => 'lazy', isa => LockType;

has 'log'          => is => 'lazy', isa => LogType,
   builder         => sub { Class::Usul::Log->new( builder => $_[ 0 ] ) };

# Construction
sub _build_lock { # There is only one lock object. Instantiate on first use
   my $self = shift; state $cache; $cache and return $cache;

   my $config = $self->config; my $attr = { %{ $config->lock_attributes } };

   merge_attributes $attr, $self,   {}, [ 'debug', 'log' ];
   merge_attributes $attr, $config, { 'exception_class' => EXCEPTION_CLASS },
                                    [ 'exception_class', 'tempdir' ];

   return $cache = IPC::SRLock->new( $attr );
}

# Public methods
sub dumper { # Damm handy for development
   my $self = shift; return data_dumper( @_ );
}

1;

__END__

=pod

=head1 Name

Class::Usul - A base class providing config, locking, logging, and l10n

=head1 Version

Describes Class::Usul version v0.51.$Rev: 1 $

=head1 Synopsis

   use Moo;

   extends q(Class::Usul);

   $self = Class::Usul->new( $attr );

=head1 Description

These modules provide a set of base classes for Perl packages and
applications that provide configuration file loading
L<Class::Usul::Config>, locking to single thread processes
L<IPC::SRLock>, logging L<Class::Usul::Log> and localisation
L<Class::Usul::L10N>

The class L<Class::Usul::Programs> is a base class for command line interfaces

Interprocess communication is handled by L<Class::Usul::IPC>

L<Class::Usul::File> makes the functionality of L<File::DataClass> available

The L<Module::Build> subclass L<Class::Usul::Build> adds methods for the
management and deployment of applications

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item config

The C<config> attribute should be a hash ref that may define key/value pairs
that provide filesystem paths for the temporary directory etc.

=item config_class

Defaults to L<Class::Usul::Config> and is of type C<LoadableClass>. An
instance of this class is loaded and instantiated using the hash ref
in the C<config> attribute. It provides accessor methods with symbol
inflation and smart defaults. Add configuration attributes by
subclassing the default

=item debug

Defaults to false

=item encoding

Decode input and encode output. Defaults to C<UTF-8>

=back

Defines an instance of L<IPC::SRLock>

Defines the application context log. Defaults to a L<Log::Handler> object

=head1 Subroutines/Methods

=head2 dumper

   $self->dumper( $some_var );

Use L<Data::Printer> to dump arguments for development purposes

=head2 _build__lock

Defines the lock object. This instantiates on first use

An L<IPC::SRLock> object which is used to single thread the
application where required. This is a singleton object.  Provides
defaults for and returns a new L<IPC::SRLock> object. The keys of the
C<< $self->config->lock_attributes >> hash are:

=over 3

=item debug

Debug status. Defaults to C<< $self->debug >>

=item log

Logging object. Defaults to C<< $self->log >>

=item tempdir

Directory used to store the lock file and lock table if the C<fcntl> backend
is used. Defaults to C<< $self->config->tempdir >>

=back

=head1 Diagnostics

Setting the I<debug> attribute to true causes messages to be logged at the
debug level

=head1 Dependencies

=over 3

=item L<Class::Usul::Constants>

=item L<Class::Usul::Functions>

=item L<Class::Usul::L10N>

=item L<Class::Usul::Log>

=item L<IPC::SRLock>

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

=head1 Acknowledgements

Larry Wall - For the Perl programming language

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
