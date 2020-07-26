package Wink;

use v5.30.0;

use Moose;

use experimental qw(signatures);

my $HIDIOCSFEATURE = 3221833734;

has device => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has _fh => (
  is    => 'ro',
  lazy  => 1,
  init_arg  => undef,
  default   => sub {
    my $device = $_[0]->device;
    open(my $fh, '+>', $device) or die "can't open $device: $!";
    return $fh;
  },
);

sub BUILD {
  $_[0]->_fh;
}

my sub _to_rgb ($arg) {
  $arg =~ s/^#//;

  $arg = "$1$1$2$2$3$3" if $arg =~ /\A([0-9a-f])([0-9a-f])([0-9a-f])\z/ia;

  Carp::confess("bad rgb") unless $arg =~ /\A[0-9a-f]{6}/ia;

  return unpack 'C*', pack 'H*', $arg;
}

sub _send ($self, $chr, @sixargs) {
  ioctl(
    $self->_fh,
    $HIDIOCSFEATURE,
    pack("C*", 1, ord($chr), @sixargs, 0),
  );

  return;
}

sub fadeto {
  my ($self, $rgb, $led, $millis) = @_;
  $led ||= 0; # or 1, or 2
  $millis ||= 50;

  $self->_send(c => _to_rgb($rgb), $millis >> 8, $millis % 0xFF, $led);

  return;
}

sub off ($self, $led = 0) {
  $self->_send(n => (0, 0, 0), 0, 0, $led);
}

__PACKAGE__->meta->make_immutable;
