use Test::More tests => 30;

BEGIN { use_ok('IWL::P2J') }

my $p = IWL::P2J->new;

sub test_general {
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

    is($p->convert(sub {my $a = 12; window::alert($a)}), "var a = 12;window.alert(a);");
    is($p->convert(sub {my $a = 12; alert($a)}), "var a = 12;alert(a);");
    is($p->convert(sub {my $a = 12; Math::max($a, 5)}), "var a = 12;Math.max(a, 5);");

    TODO: {
        local $TODO = "not implemented";

        is($p->convert(sub {my $a = 12; if ($a) {my $b = $a / 2}}), "var a = 12;if (a) {var b = a / 2;}");
        is($p->convert(sub {my $a = 12; unless ($a) {my $b = $a / 2}}), "var a = 12;if (!(a)) {var b = a / 2;}");
        is($p->convert(sub {my $a = 12; while ($a) {my $b = $a / 2}}), "var a = 12;while (a) {var b = a / 2;}");
        is($p->convert(sub {my $a = 12; until ($a) {my $b = $a / 2}}), "var a = 12;while (!(a)) {var b = a / 2;}");
        is($p->convert(sub {my $a = 12; for (my $i = 0; $i < 100; ++$i) {my $b = $a / 2}}), "var a = 12;for (var i = 0; i < 100; ++i) {var b = a / 2;}");
        is($p->convert(sub {my $a = 12; for (1 .. 100) {my $b = $a / 2}}), "var a = 12;for (var _ = 1; _ < 101; ++_) {var b = a / 2;}");
        is($p->convert(sub {my $a = 12; for (1,6,21,4) {my $b = $a / 2}}), q|var a = 12;var _$ = [1,6,21,4];for (var i = 0, _ = _$[0]; i < _$.length; _ = _$[++i]) {var b = a / 2;}delete _$;|);
        is($p->convert(sub {my %a = (a => 1, b => 2); for (keys %a) {my $b = $a{$_}}}), q|var a = {'a': 1, 'b': 2};for (var _ in a) {var b = a[_];}|);
    }
}

sub test_lexical {
    my $a = 42;
    my $b = 'foo';
    my @c = (1,2,3);
    my %d = (a => 1, b => $a);
    my $e = [7,8,9];
    my $f = {c => $b , d => $e};

    is($p->convert(sub {my $v = $a}), 'var v = 42;');
    is($p->convert(sub {my $v = $b}), 'var v = "foo";');
    is($p->convert(sub {my $v = @c}), 'var v = [1, 2, 3];');
    is($p->convert(sub {my $v = %d}), 'var v = {"a": 1, "b": 42};');
    is($p->convert(sub {my $v = $e}), 'var v = [7, 8, 9];');
    is($p->convert(sub {my $v = $f}), 'var v = {"c": "foo", "d": [7, 8, 9]};');
}

test_general;
test_lexical;
