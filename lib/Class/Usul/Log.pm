package Class::Usul::Log;

use Class::Null;
use Class::Usul::Constants qw( FALSE LOG_LEVELS NUL TRUE );
use Class::Usul::Functions qw( merge_attributes );
use Class::Usul::Types     qw( Bool EncodingType HashRef
                               LoadableClass LogType Undef );
use Encode;
use File::Basename         qw( dirname );
use File::DataClass::Types qw( Path );
use Scalar::Util           qw( blessed );

use namespace::clean -except => [ qw( class_stash meta ) ];

use Moo;
use MooX::ClassStash;

has '_debug_flag'     => is => 'ro',   isa => Bool, default => FALSE,
   init_arg           => 'debug';

has '_encoding'       => is => 'ro',   isa => EncodingType | Undef,
   init_arg           => 'encoding';

has '_log'            => is => 'lazy', isa => LogType, init_arg => 'log';

has '_log_attributes' => is => 'ro',   isa => HashRef, default => sub { {} },
   init_arg           => 'log_attributes';

has '_log_class'      => is => 'lazy', isa => LoadableClass,
   coerce             => LoadableClass->coercion, default => 'Log::Handler',
   init_arg           => 'log_class';

has '_logfile'        => is => 'ro',   isa => Path | Undef,
   coerce             => Path->coercion, init_arg => 'logfile';

around 'BUILDARGS' => sub {
   my ($orig, $class, @args) = @_; my $attr = $orig->( $class, @args );

   my $builder = delete $attr->{builder} or return $attr;
   my $config  = $builder->can( 'config' ) ? $builder->config : {};

   merge_attributes $attr, $builder, {}, [ 'debug', 'encoding' ];
   merge_attributes $attr, $config,  {},
      [ qw( encoding log_attributes log_class logfile ) ];

   return $attr;
};

sub BUILD {
   my $self = shift; my $class = blessed $self; my $meta = $class->class_stash;

   for my $method (LOG_LEVELS) {
      $meta->has_method( $method ) or $meta->add_method( $method => sub {
         my ($self, $text) = @_; $text or return FALSE;

         $text = "${text}"; chomp $text; $text .= "\n";
         $self->_encoding and $text = encode( $self->_encoding, $text );
         $self->_log->$method( $text );
         return TRUE;
      } );

      my $meth_msg = "${method}_message";

      $meta->has_method( $meth_msg ) or $meta->add_method( $meth_msg => sub {
         my ($self, $opts, $msg) = @_; my $text;

         my $user = $opts->{user} ? $opts->{user}->username : 'unknown';

         $msg ||= NUL; $msg = "${msg}"; chomp $msg;
         $text  = (ucfirst $opts->{leader} || NUL)."[${user}] ".
                  (ucfirst $msg || 'no message');
         $self->$method( $text );
         return TRUE;
      } );
   }

   return;
}

sub filehandle {
   return $_[ 0 ]->_log->output( 'file-out' )->{fh};
}

sub get_log_attributes {
   my $self = shift; my $attr = { %{ $self->_log_attributes } };

   $self->_log_class eq 'Log::Handler' or return $attr;

   my $fattr   = $attr->{file} ||= {};
   my $logfile = $fattr->{filename} || $self->_logfile;

   ($logfile and -d dirname( "${logfile}" )) or return;

   $fattr->{alias   }   = 'file-out';
   $fattr->{filename}   = "${logfile}";
   $fattr->{maxlevel}   = $self->_debug_flag
                        ? 'debug' : $fattr->{maxlevel} || 'info';
   $fattr->{mode    } ||= 'append';
   return $attr;
}

# Private methods
sub _build__log {
   my $self = shift; my $attr = $self->get_log_attributes;

   return $attr ? $self->_log_class->new( %{ $attr } ) : Class::Null->new;
}

1;

__END__

=pod

=head1 Name

Class::Usul::Log - Create methods for each logging level that encode their output

=head1 Synopsis

   use Moo;
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

=item C<debug>

Debug flag defaults to FALSE

=item C<encoding>

Optional output encoding. If present output to the logfile is encoded

=item C<log>

Optional log object. Will instantiate an instance of L<Log::Handler> if this
is not provided

=item C<log_attributes>

Attributes used to create the log object

=item C<logfile>

Path to the logfile

=back

=head1 Subroutines/Methods

=head2 C<BUILDARGS>

Monkey with the constructors signature

=head2 C<BUILD>

Creates a set of methods defined by the C<LOG_LEVELS> constant. The
method expects C<< $self->log >> and C<< $self->encoding >> to be set.
It encodes the output string prior calling the log method at the given
level

=head2 C<filehandle>

Return the loggers file handle

=head2 get_log_attributes

Returns the hash ref passed to the constructor of the log class. Returns
undef to indicate no logging, an instance of L<Class::Null> is used
instead

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Null>

=item L<Class::Usul::Constants>

=item L<Class::Usul::Functions>

=item L<Moo>

=item L<Encode>

=item L<File::DataClass::Types>

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
