package Wink;

use v5.30.0;
use warnings;

use experimental qw(signatures);

use Carp qw(confess);

my %Via = (
  command => sub ($arg) {
    require Wink::Driver::Command;
    Wink::Driver::Command->new({ command => $arg });
  },
  device => sub ($arg) {
    require Wink::Driver::Device;
    Wink::Driver::Device->new({ device => $arg });
  },
);

sub get_driver {
  my $self = shift;

  my ($which, $how);
  if (@_) {
    ($which, $how) = @_;
  } elsif ($ENV{WINK_DRIVER}) {
    ($which, $how) = split /(?<!:):(?!:)/, $ENV{WINK_DRIVER}, 2;
  }

  confess("no driver specification available") unless $which;
  confess("unknown driver type") unless $Via{$which};
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

    $device{$name} = $self->get_driver($which, $how);
  }

  require Wink::Bank;
  return Wink::Bank->new({ devices => \%device });
}

1;
