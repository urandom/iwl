use Test::More tests => 7;

use IWL::ProgressBar;

my $p = IWL::ProgressBar->new;
is($p->setText('Progress: #{percent}'), $p);
is($p->getText, 'Progress: #{percent}');
is($p->setValue(0.25), $p);
is($p->getValue, 0.25);
ok(!$p->isPulsating);
is($p->setPulsate(1), $p);
ok($p->isPulsating);
