package Wink::Device;

use v5.28.0;

use Moose::Role;

use experimental qw(signatures);

requires 'set';
requires 'fadeto';

sub off ($self, $led = 0) {
  $self->set('000000', $led);
}

no Moose::Role;
1;
