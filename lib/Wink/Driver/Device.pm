package Wink::Driver::Device;

use v5.30.0;

use Moose;
with 'Wink::Driver';

use experimental qw(signatures);

use Wink::Util qw(to_rgb);

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

sub _send ($self, $chr, @sixargs) {
  ioctl(
    $self->_fh,
    $HIDIOCSFEATURE,
    pack("C*", 1, ord($chr), @sixargs, 0),
  );

  return;
}

sub fadeto ($self, $rgb, $ms = 50, $led = 0) {
  return $self->set($rgb, $led) if $ms == 0;

  $ms = $ms / 10;
  $self->_send(c => to_rgb($rgb), $ms >> 8, $ms % 0xFF, $led);

  return;
}

sub set ($self, $rgb, $led = 0) {
  $self->_send(n => to_rgb($rgb), 0, 0, $led);
}

sub off ($self, $led = 0) {
  $self->_send(n => (0, 0, 0), 0, 0, $led);
}

__PACKAGE__->meta->make_immutable;
