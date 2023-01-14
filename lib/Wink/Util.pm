package Wink::Util;

use v5.28.0;
use warnings;

use experimental qw(signatures);

use Sub::Exporter -setup => [ qw(to_rgb get_serial_dev_map) ];

sub to_rgb ($arg) {
  $arg =~ s/^#//;

  $arg = "$1$1$2$2$3$3" if $arg =~ /\A([0-9a-f])([0-9a-f])([0-9a-f])\z/ia;

  Carp::confess("bad rgb") unless $arg =~ /\A[0-9a-f]{6}/ia;

  return unpack 'C*', pack 'H*', $arg;
}

# pass me an arrayref of /dev/... devices on the usb bus
sub get_serial_dev_map () {
  require Process::Status;

  my @lines = `lsusb -d 27b8:01ed`;
  Process::Status->assert_ok("listing USB devices");

  my @devices;
  for my $line (@lines) {
    next unless $line =~ /^Bus ([0-9]+) Device ([0-9]+):/;
    push @devices, "/dev/bus/usb/$1/$2";
  }

  my %device;
  DEV: for my $blink_dev (@devices) {
    my @info = `udevadm info $blink_dev`;
    my ($path)   = map {; /^P: (\S+)$/m ? $1 : () } @info;
    my ($serial) = map {; /ID_SERIAL_SHORT=([[:xdigit:]]+)/ ? $1 : () } @info;

    unless ($path and $serial) {
      warn "Couldn't figure out $blink_dev\n";
      next DEV;
    }

    $device{$serial} = {
      path => $path,
    };
  }

  HID: for my $hid_dev (</dev/hidraw*>) {
    next unless -w $hid_dev;

    my ($path) = map {; /^P: (\S+)$/m ? $1 : () } `udevadm info $hid_dev`;
    unless ($path) {
      warn "No path line for $hid_dev!\n";
      next HID;
    }

    my @found = grep {; index($path, $device{$_}{path}) == 0 } keys %device;

    if (@found > 1) { warn "too many matches for $hid_dev\n"; next HID; }
    if (@found < 1) { warn "no many matches for $hid_dev\n";  next HID; }

    $device{$found[0]}{hid} = $hid_dev;
  }

  return { map { $_ => $device{$_}{hid} } keys %device };
}

1;
