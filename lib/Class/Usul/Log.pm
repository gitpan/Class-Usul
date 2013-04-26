# @(#)$Id: Log.pm 279 2013-04-26 17:56:22Z pjf $

package Class::Usul::Log;

use version; our $VERSION = qv( sprintf '0.15.%d', q$Rev: 279 $ =~ /\d+/gmx );

use Class::Null;
use Class::Usul::Moose;
use Class::Usul::Constants;
use Class::Usul::Functions       qw(merge_attributes);
use Encode;
use File::Basename               qw(dirname);
use File::DataClass::Constraints qw(Path);

has '_debug_flag'     => is => 'ro',   isa => Bool, init_arg => 'debug',
   default            => FALSE;

has '_encoding'       => is => 'ro',   isa => EncodingType | Undef,
   init_arg           => 'encoding';

has '_log'            => is => 'lazy', isa => LogType, init_arg => 'log';

has '_log_attributes' => is => 'ro',   isa => HashRef,
   init_arg           => 'log_attributes', default => sub { {} };

has '_log_class'      => is => 'lazy', isa => LoadableClass, coerce => TRUE,
   default            => sub { 'Log::Handler' }, init_arg => 'log_class';

has '_logfile'        => is => 'ro',   isa => Path | Undef, coerce => TRUE,
   init_arg           => 'logfile';

around 'BUILDARGS' => sub {
   my ($next, $class, @rest) = @_; my $attr = $class->$next( @rest );

   my $builder = delete $attr->{builder} or return $attr;
   my $config  = $builder->can( q(config) ) ? $builder->config : {};

   merge_attributes $attr, $builder, {}, [ qw(debug encoding) ];
   merge_attributes $attr, $config,  {},
      [ qw(encoding log_attributes log_class logfile) ];

   return $attr;
};

sub BUILD {
   my $self = shift; my $class = blessed $self; my $meta = $class->meta;

   $meta->make_mutable;

   for my $method (LOG_LEVELS) {
      $meta->has_method( $method ) or $meta->add_method( $method => sub {
         my ($self, $text) = @_; $text or return; chomp $text;

         $self->_encoding and $text = encode( $self->_encoding, $text );
         $self->_log->$method( $text."\n" );
         return;
      } );

      my $meth_msg = "${method}_message";

      $meta->has_method( $meth_msg ) or $meta->add_method( $meth_msg => sub {
         my ($self, $opts, $msg) = @_; my $text;

         my $user = $opts->{user} ? $opts->{user}->username : q(unknown);

         $msg ||= NUL; $msg = NUL.$msg; chomp $msg;
         $text  = (ucfirst $opts->{leader} || NUL)."[${user}] ";
         $text .= (ucfirst $msg || 'no message');
         $self->$method( $text );
         return;
      } );
   }

   $meta->make_immutable;
   return;
}

sub fh {
   return $_[ 0 ]->_log->output( 'file-out' )->{fh};
}

# Private methods

sub _build__log {
   my $self    = shift;
   my $attr    = { %{ $self->_log_attributes } };
   my $fattr   = $attr->{file} ||= {};
   my $logfile = $fattr->{filename} || $self->_logfile;

   ($logfile and -d dirname( NUL.$logfile )) or return Class::Null->new;

   $fattr->{alias   }   = 'file-out';
   $fattr->{filename}   = NUL.$logfile;
   $fattr->{maxlevel}   = $self->_debug_flag
                        ? 'debug' : $fattr->{maxlevel} || 'info';
   $fattr->{mode    } ||= q(append);

   return $self->_log_class->new( %{ $attr } );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 Name

Class::Usul::Log - Create methods for each logging level that encode their output

=head1 Version

0.15.$Revision: 279 $

=head1 Synopsis

   use Class::Usul::Moose;
   use Class::Usul::Log;

   has '_log' => is => 'ro', isa => LogType,
      lazy    => TRUE,   builder => '_build__log',
      reader  => 'log', init_arg => 'log';

   sub _build__log {
      my $self = shift; return Class::Usul::Log->new( builder => $self );
   }

   # Can now call the following
   $self->log->debug( $text );
   $self->log->info(  $text );
   $self->log->warn(  $text );
   $self->log->error( $text );
   $self->log->fatal( $text );

=head1 Description

Creates methods for each logging level that encode their output. The
logging levels are defined by the
L<log levels|Class::Usul::Constants/LOG_LEVELS> constant

=head1 Configuration and Environment

Defines the following attributes

=over 3

=item debug

Debug flag defaults to FALSE

=item encoding

Optional output encoding. If present output to the logfile is encoded

=item log

Optional log object. Will instantiate an instance of L<Log::Handler> if this
is not provided

=item log_attributes

Attributes used to create the log object

=item logfile

Path to the logfile

=back

=head1 Subroutines/Methods

=head2 BUILD

Creates a set of methods defined by the C<LOG_LEVELS> constant. The
method expects C<< $self->log >> and C<< $self->encoding >> to be set.
It encodes the output string prior calling the log method at the given
level

=head2 fh

Return the loggers file handle

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Null>

=item L<Class::Usul::Constants>

=item L<Class::Usul::Functions>

=item L<Class::Usul::Moose>

=item L<Encode>

=item L<File::DataClass::Constraints>

=item L<Log::Handler>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

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
