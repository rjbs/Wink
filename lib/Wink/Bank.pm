package Wink::Bank;

use v5.30.0;
use Moose;

use experimental qw(signatures);

has devices => (
  reader => '_devices',
  is     => 'ro',
  required => 1,
);

sub BUILD {
  Carp::confess("You created a zero-device Wink::Bank.  Why so serious?")
    unless keys %{ $_[0]->_devices };

  return;
}

sub device_names { keys %{ $_[0]->_devices } }
sub device_named { $_[0]->_devices->{$_[1]} }

sub build_program ($self, $instr) {
  require Wink::Program;

  my $program = Wink::Program->new({ bank => $self });
  $program->_add_instruction($_) for @$instr;

  return $program;
}

no Moose;
__PACKAGE__->meta->make_immutable;
