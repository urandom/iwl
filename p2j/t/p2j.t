use Test::More tests => 20;

BEGIN { use_ok('IWL::P2J') }

my $p = IWL::P2J->new;

{
    is($p->convert(sub {}), '');
    is($p->convert(sub {my $a = 12}), "var a = 12;");
    is($p->convert(sub {my $foo = "bar"}), "var foo = 'bar';");
    is($p->convert(sub {my @a = (1,2,3)}), "var a = [1, 2, 3];");
    is($p->convert(sub {my $a = [1,2,3]}), "var a = [1, 2, 3];");
    is($p->convert(sub {my %a = (a => 1)}), "var a = {'a': 1};");
    is($p->convert(sub {my $a = {a => 1}}), "var a = {'a': 1};");

    is($p->convert(sub {my $a = 12; my $b = $a ? 42 : ''}), "var a = 12;var b = a ? 42 : '';");
    is($p->convert(sub {my $a = 12; my $b = 42 if $a}), "var a = 12;if ( a) var b = 42;");
    is($p->convert(sub {my $a = 12; my $b = 42 unless $a}), "var a = 12;if (!( a)) var b = 42;");
    is($p->convert(sub {my $a = 12; my $b = 42 while $a}), "var a = 12;while ( a) var b = 42;");
    is($p->convert(sub {my $a = 12; my $b = 42 until $a}), "var a = 12;while (!( a)) var b = 42;");

    is($p->convert(sub {my $a = 12; $window->alert($a)}), "var a = 12;window.alert(a);");
    is($p->convert(sub {my $a = 12; alert($a)}), "var a = 12;alert(a);");
    is($p->convert(sub {my $a = 12; $Math->max($a, 5)}), "var a = 12;Math.max(a, 5);");

    TODO: {
        local $TODO = "not implemented";
        is($p->convert(sub {my $a = 12; if ($a) {my $b = $a / 2}}), "var a = 12;if (a) {var b = a / 2;}");
        is($p->convert(sub {my $a = 12; unless ($a) {my $b = $a / 2}}), "var a = 12;if (!(a)) {var b = a / 2;}");
        is($p->convert(sub {my $a = 12; while ($a) {my $b = $a / 2}}), "var a = 12;while (a) {var b = a / 2;}");
        is($p->convert(sub {my $a = 12; until ($a) {my $b = $a / 2}}), "var a = 12;while (!(a)) {var b = a / 2;}");
    }
}
