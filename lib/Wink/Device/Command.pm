package Wink::Device::Command;

use v5.28.0;

use Moose;
with 'Wink::Device';

use experimental qw(signatures);

has command => (
  is  => 'ro',
  isa => 'Str',
  default => 'blink1-tool',
);

has device_id => (
  is  => 'ro',
  isa => 'Str',
  default => '0', # can also be "all"
);

sub _do_command ($self, @args) {
  open my $out, '>&STDOUT';
  close STDOUT;
  system($self->command, '--id', $self->device_id, @args);

  warn "failed to run command" if $?;

  open STDOUT, '>&', $out;

  return;
}

sub fadeto ($self, $rgb, $ms = 0, $led = 0) {
  $self->_do_command(
    '-m',     $ms,
    '--rgb',  $rgb,
    '--led',  $led,
  );

  return;
}

sub set ($self, $rgb, $led = 0) {
  return $self->fadeto($rgb, 0, $led);
}

__PACKAGE__->meta->make_immutable;
