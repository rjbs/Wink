package Wink;

use v5.30.0;
use warnings;

use experimental qw(signatures);

use Carp qw(confess);

my %Via = (
  command => sub ($arg) {
    require Wink::Device::Command;
    my ($command, $device_id) = split /:/, $arg, 2;
    Wink::Device::Command->new({
      command => $command,
      (length $device_id ? (device_id => $device_id) : ()),
    });
  },
  device => sub ($arg) {
    require Wink::Device::HIDRaw;
    Wink::Device::HIDRaw->new({ device => $arg });
  },
);

sub get_device {
  my $self = shift;

  my ($which, $how);
  if (@_) {
    ($which, $how) = @_;
  } elsif ($ENV{WINK_DEVICE}) {
    ($which, $how) = split /(?<!:):(?!:)/, $ENV{WINK_DEVICE}, 2;
  }

  confess("no device specification available") unless $which;
  confess("unknown device type") unless $Via{$which};
  return $Via{$which}->($how);
}

sub get_bank ($self) {
  confess("\$WINK_BANK not defined") unless defined $ENV{WINK_BANK};

  my %device;
  my @entries = split /,/, $ENV{WINK_BANK};
  for my $entry (@entries) {
    my ($name, $which, $how) = split /(?<!:):(?!:)/, $entry, 3;

    confess(qq{device "$name" defined multiple times in \$WINK_BANK})
      if $device{$name};

    $device{$name} = $self->get_device($which, $how);
  }

  require Wink::Bank;
  return Wink::Bank->new({ devices => \%device });
}

1;
