package Wink::Bank::Debug;

use v5.36.0;
use Moose;

extends 'Wink::Bank';

use experimental qw(signatures);

sub dispatch ($self, $name, $method, @args) {
  warn sprintf "%6s: %s [ %s ]\n", $name, $method, "@args";
  return;
}

sub msleep ($self, $ms) {
  warn sprintf "%6s: %sms\n", 'sleep', $ms;
  return;
}

no Moose;
__PACKAGE__->meta->make_immutable;
