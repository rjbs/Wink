package Wink::Bank;

use v5.30.0;
use Moose;

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

no Moose;
__PACKAGE__->meta->make_immutable;
