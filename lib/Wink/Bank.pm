package Wink::Bank;

use v5.30.0;
use Moose;

has winks => (
  reader => '_winks',
  is     => 'ro',
  required => 1,
);

sub BUILD {
  Carp::confess("You created a zero-wink Wink::Bank.  Why so serious?")
    unless keys %{ $_[0]->_winks };

  return;
}

sub wink_names { keys %{ $_[0]->_winks } }
sub wink_named { $_[0]->_winks->{$_[1]} }

no Moose;
__PACKAGE__->meta->make_immutable;
