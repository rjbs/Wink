package Wink::Program;

use v5.36.0;
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
  lazy    => 1,
  reader  => '_queue_times',
  traits  => [ 'Hash' ],
  default => sub {
    return {
      # We need two queues per device.  One per LED.
      map {; "$_\_1" => 0, "$_\_2" => 0 } $_[0]->bank->device_names
    };
  },
  handles => {
    _queue_names => 'keys',
  },
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

  my @queues = map {; $led ? "$_\_$led" : ("$_\_1", "$_\_2") } @names;

  return {
    time => { map {; $_ => $fade + $hold } @queues },
    code => sub ($self) {
      $self->bank->dispatch($_ => fadeto => ($arg->{rgb}, $fade, $led)) for @names;
    },
  }
}

sub _instr_sleep ($self, $arg) {
  my $time = $arg->{time} || confess "can't sleep without time in ms";

  return {
    time  => { map {; $_ => -$time } $self->_queue_names },
    code  => sub { $self->bank->msleep($time); },
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
  my $device_name = $arg->{device};
  my $led         = $arg->{led};

  my @candidates;

  if (defined $device_name) {
    @candidates = (defined $led)
                ? ("$device_name\_$led")
                : ("$device_name\_1", "$device_name\_2");
  } else {
    confess("led specified, but not device!") if defined $led;

    @candidates = $self->_queue_names;
  }

  my $queue_time = $self->_queue_times;

  my @unknown = grep {; ! exists $queue_time->{$_} } @candidates;

  confess("unknown queue considered: @unknown") if @unknown;

  my ($queue_name) = sort {; $queue_time->{$b} <=> $queue_time->{$a} }
                     @candidates;

  my $time = $queue_time->{$queue_name};

  unless ($time) {
    return;
  }

  return {
    time  => { map {; $_ => -$time } $self->_queue_names },
    code  => sub { $self->bank->msleep($time); }
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

  my $sync = $arg->{sync};

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
