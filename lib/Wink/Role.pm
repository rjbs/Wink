package Wink::Role;

use v5.30.0;

use Moose::Role;

use experimental qw(signatures);

requires 'set';
requires 'off';
requires 'fadeto';

no Moose::Role;
1;
