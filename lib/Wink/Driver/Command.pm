package Wink::Driver::Command;

use v5.30.0;

use Moose;
with 'Wink::Driver';

use experimental qw(signatures);

has command => (
  is  => 'ro',
  isa => 'Str',
  default => 'blink1-tool',
);

sub _do_command ($self, @args) {
  open my $out, '>&STDOUT';
  close STDOUT;
  system($self->command, @args);

  warn "failed to run command" if $?;

  open STDOUT, '>&', $out;

  return;
}

sub fadeto ($self, $rgb, $ms = 50, $led = 0) {
  $self->_do_command(
    ($ms == 0 ? () : ('-m', $ms)),
    '--rgb', $rgb,
    '--led', $led,
  );

  return;
}

sub set ($self, $rgb, $led = 0) {
  return $self->fadeto($rgb, 0, $led);
}

sub off ($self, $led = 0) {
  $self->_do_command('--led', $led, '--off');
}

__PACKAGE__->meta->make_immutable;
