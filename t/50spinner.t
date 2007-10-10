use Test::More tests => 19;

use IWL::Spinner;

my $s = IWL::Spinner->new(id => 'spinner');
is($s->setRange(-25, 162.12), $s);
is_deeply([$s->getRange], [-25, 162.12]);
is($s->setPrecision(3), $s);
is($s->getPrecision, 3);
is($s->setIncrements(2, 12.5), $s);
is_deeply([$s->getIncrements], [2, 12.5]);
is($s->setAcceleration(1.25), $s);
is($s->getAcceleration, 1.25);
is($s->setValue(15.2), $s);
is($s->getValue, 15.2);
ok(!$s->isWrapping);
is($s->setWrap(1), $s);
ok($s->isWrapping);
ok(!$s->isSnapping);
is($s->setSnap(1), $s);
ok($s->isSnapping);
ok(!$s->getMask);
is($s->setMask("#{number} лв"), $s);
is($s->getMask, "#{number} лв");
