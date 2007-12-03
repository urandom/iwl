use Test::More tests => 9;

use IWL::Expander;
use IWL::Image;

my $e = IWL::Expander->new;

ok(!$e->getExpanded);
is($e->setExpanded(1), $e);
ok($e->getExpanded);
ok(!$e->getLabelWidget);
is($e->setLabelWidget(IWL::Image->new), $e);
isa_ok($e->getLabelWidget, 'IWL::Image');
is($e->getLabel, '');
is($e->setLabel('Foo Бар'), $e);
is($e->getLabel, 'Foo Бар');
