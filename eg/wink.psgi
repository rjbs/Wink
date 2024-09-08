use v5.36.0;

use JSON::MaybeXS;
use Plack::Request;
use Time::HiRes qw(usleep);
use Wink;

use experimental qw(for_list signatures);

my $Bank = Wink->get_bank;
my ($Default_Device) = sort { $a cmp $b } $Bank->device_names;

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

  # my $time = 0;
  my @plan;
  my $program = $Bank->build_program($instr);

  # return error("Maximum play time exceeded") if $time > 15 * 1000;

  $program->execute;

  return [
    204,
    [],
    [ "" ],
  ];
}
