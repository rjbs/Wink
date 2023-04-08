package Wink;

use v5.36.0;

use experimental qw(signatures);

use Carp qw(confess);
use Wink::Util;

my %Via = (
  command => sub ($arg) {
    require Wink::Device::Command;
    my ($command, $device_id) = split /:/, $arg, 2;
    Wink::Device::Command->new({
      command => $command,
      (length $device_id ? (device_id => $device_id) : ()),
    });
  },
  hidraw => sub ($arg) {
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
  confess(qq{unknown device type "$which"}) unless $Via{$which};
  return $Via{$which}->($how);
}

sub get_bank ($self) {
  my %device;

  if ($ENV{WINK_SERIALS}) {
    my @serials = split /,/, $ENV{WINK_SERIALS};
    my @paths   = map {; "/dev/blink/$_" } @serials;

    if (my @missing = grep { ! -e } @paths) {
      confess("\$WINK_SERIALS led to missing paths: @missing");
    }

    for my $i (keys @paths) {
      $device{$i} = $self->get_device(hidraw => $paths[$i]);
    }
  } elsif ($ENV{WINK_BANK}) {
    my @entries = split /,/, $ENV{WINK_BANK};
    for my $entry (@entries) {
      my ($name, $which, $how) = split /(?<!:):(?!:)/, $entry, 3;

      confess(qq{device "$name" defined multiple times in \$WINK_BANK})
        if $device{$name};

      $device{$name} = $self->get_device($which, $how);
    }
  } else {
    confess("neither \$WINK_SERIALS nor \$WINK_BANK defined");
  }

  my $class;

  if ($ENV{WINK_DEBUG}) {
    require Wink::Bank::Debug;
    $class = 'Wink::Bank::Debug';
  } else {
    require Wink::Bank;
    $class = 'Wink::Bank';
  }

  return $class->new({ devices => \%device });
}

1;
