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

sub fadeto {
  my ($self, $r, $g, $b, $led, $millis) = @_;
  $led ||= 0; # or 1, or 2
  $millis ||= 50;

  ioctl(
    $self->_fh,
    $HIDIOCSFEATURE,
    pack("C*", 1, ord('c'), $r, $g, $b, $millis >> 8, $millis % 0xFF, $led, 0)
  );

  return;
}

__PACKAGE__->meta->make_immutable;
