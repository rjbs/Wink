package Wink::Driver::Comand;

use v5.30.0;

use Moose;
with 'Wink::Driver';

use experimental qw(signatures);

has command => (
  is  => 'ro',
  isa => 'Str',
  default => 'blink1-tool',
);

sub fadeto ($self, $rgb, $ms = 50, $led = 0) {
  system(
    $self->command,
    ($ms == 0 ? () : ('-m', $ms)),
    '--rgb', $rgb,
    '--led', $led,
  );

  warn "failed to run command" if $?;
  return;
}

sub set ($self, $rgb, $led = 0) {
  return $self->fadeto($rgb, 0, $led);
}

sub off ($self, $led = 0) {
  system($self->command, '--led', $led, '--off');
}

__PACKAGE__->meta->make_immutable;
