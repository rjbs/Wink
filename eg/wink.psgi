use v5.32.0;
use warnings;

use JSON::MaybeXS;
use Plack::Request;
use Time::HiRes qw(usleep);
use Wink;

use experimental qw(signatures);

my $Wink = Wink->get_driver;

my sub error ($str) {
  return [
    400,
    [ 'Content-Type' => 'application/json' ],
    [ encode_json({ error => "$str" }) ],
  ]
}

sub {
  my ($env) = @_;
  my $req = Plack::Request->new($env);

  my $input = $req->input;
  my $json  = do { local $/; <$input> };
  my $instr = decode_json($json);

  my $time = 0;
  my @plan;

  # set   color => color, fadetime => ms
  # sleep ms  => ms
  # off
  INSTR: for my $instr (@$instr) {
    if ($instr->{cmd} eq 'off')   {
      push @plan, sub { $Wink->off };
      next INSTR;
    }

    if ($instr->{cmd} eq 'sleep') {
      return error("Invalid sleep specification")
        unless defined($instr->{ms}) && 0 < $instr->{ms} < 5000;

      push @plan, sub { usleep($instr->{ms} * 1000) };

      $time += $instr->{ms} / 1000;
      next INSTR;
    }

    if ($instr->{cmd} eq 'set') {
      return error("Invalid color specification")
        unless $instr->{color} && $instr->{color} =~ /\A[0-9A-Fa-f]{6}\z/;

      if ($instr->{fadetime}) {
        push @plan, sub {
          $Wink->fadeto($instr->{color}, $instr->{fadetime});
          usleep $instr->{fadetime} * 1000;
        };
        $time += $instr->{fadetime} / 1000;
      } else {
        push @plan, sub { $Wink->set($instr->{color}); };
      }

      next INSTR;
    }

    return error("Unknown command");
  }

  return error("Maximum play time exceeded") if $time > 15 * 1000;

  $_->() for @plan;

  return [
    204,
    [],
    [ "" ],
  ];
}
