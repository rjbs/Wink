package Wink::Util;

use v5.36.0;

use experimental qw(signatures);

use Sub::Exporter -setup => [ qw(to_rgb) ];

sub to_rgb ($arg) {
  $arg =~ s/^#//;

  $arg = "$1$1$2$2$3$3" if $arg =~ /\A([0-9a-f])([0-9a-f])([0-9a-f])\z/ia;

  Carp::confess("bad rgb") unless $arg =~ /\A[0-9a-f]{6}/ia;

  return unpack 'C*', pack 'H*', $arg;
}

1;
