package Wink::Program;

use v5.30.0;
use Moose;

use experimental qw(signatures);

use Time::HiRes ();

# instructions
# total time
# validate ?
# validate-against-bank?
# execute

has bank => (
  is        => 'ro',
  required  => 1,
);

has coderefs => (
  init_arg  => undef,
  traits    => [ 'Array' ],
  default   => sub {  []  },
  handles   => {
    _add_coderef  => 'push',
    _coderefs     => 'elements',
  },
);

has queue_times => (
  lazy  => 1,
  reader  => '_queue_times',
  default => sub {
    return { map {; $_ => 0 } $_[0]->bank->device_names };
  }
);

sub _update_queue_times ($self, $update) {
  my $queue_times = $self->_queue_times;

  for my $name (keys %$update) {
    $queue_times->{$name} += $update->{$name};
    $queue_times->{$name} = 0 if $queue_times->{$name} < 0;
  }

  return;
}

sub _instr_set ($self, $arg) {
  my $led = $arg->{led} // 0;

  my $fade = $arg->{fade} // 0;
  my $hold = $arg->{hold} // 0;

  # validate, esp. rgb + device name

  my @names = length $arg->{device}
            ? $arg->{device}
            : $self->bank->device_names;

  return {
    time => { map {; $_ => $fade + $hold } @names },
    code => sub ($self) {
      $self->bank->device_named($_)->fadeto($arg->{rgb}, $fade, $led) for @names;
    },
  }
}

sub _instr_sleep ($self, $arg) {
  my $time = $arg->{time} || confess "can't sleep without time in ms";

  return {
    time  => { map {; $_ => -$time } $self->bank->device_names },
    code  => sub {
      Time::HiRes::usleep($time * 1_000);
    },
  };
}

sub _instr_off ($self, $arg) {
  $self->_instr_set({
    fade  => $arg->{fade}  // 0,
    led   => $arg->{led}   // 0,
    rgb   => '000000',
    (length $arg->{device} ? (device => $arg->{device}) : ()),
  });
}

sub _instr_sync ($self, $arg) {
  my $name = $arg->{device};
  my $queue_time = $self->_queue_times;

  unless ($name) {
    ($name) = sort { $queue_time->{$b} <=> $queue_time->{$a} }
              $self->bank->device_names;
  }

  my $time = $queue_time->{$name};

  unless ($time) {
    return;
  }

  return {
    time  => { map {; $_ => -$time } $self->bank->device_names },
    code  => sub {
      Time::HiRes::usleep($time * 1_000);
    },
  }
}

sub _instr_syncoff ($self, $arg) {
  confess "shutdown takes no arguments" if keys %$arg;
  return (
    $self->_instr_sync({}),
    $self->_instr_off({}),
  );
}

sub _add_instruction ($self, $instr) {
  my ($what, $arg, @wtf) = @$instr;

  my $method = "_instr_$what";
  confess "unknown instruction: $what" unless $self->can($method);

  confess "too many parameters to method call" if @wtf;

  my $sync = delete $arg->{sync};

  for my $thing (
    $self->$method($arg),
  ) {
    $self->_update_queue_times($thing->{time})  if $thing->{time};
    $self->_add_coderef($thing->{code})         if $thing->{code};
  }

  for my $thing (
    ($sync ? $self->_instr_sync({ device => $arg->{device} }) : ()),
  ) {
    $self->_update_queue_times($thing->{time})  if $thing->{time};
    $self->_add_coderef($thing->{code})         if $thing->{code};
  }

  return;
}

sub from_instructions ($class, $instr) {
  my $self = $class->new;
  $self->_add_instruction($_) for @$instr;

  return $self;
}

sub execute ($self, $arg = {}) {
  unless (exists $arg->{shutdown} && ! $arg->{shutdown}) {
    $self->_add_instruction([ syncoff => {} ]);
  }

  $self->$_ for $self->_coderefs;
}

no Moose;
__PACKAGE__->meta->make_immutable;
