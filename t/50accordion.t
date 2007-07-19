use Test::More tests => 14;

use IWL::Accordion;

my $a = IWL::Accordion->new(resizeSpeed => 4);
isa_ok($a->appendPage('Future page'), 'IWL::Accordion::Page');
isa_ok($a->prependPage('First page', IWL::Text->new('First text')), 'IWL::Accordion::Page');
is($a->getOrientation, 'vertical');
is($a->setOrientation('horizontal'), $a);
is($a->getOrientation, 'horizontal');
is($a->getResizeSpeed, '4');
is($a->setResizeSpeed('3'), $a);
is($a->getResizeSpeed, '3');
is($a->getEventActivation, 'click');
is($a->setEventActivation('mouseout'), $a);
is($a->getEventActivation, 'mouseout');
is_deeply({$a->getDefaultSize}, {width => undef, height => undef});
is($a->setDefaultSize(width => 300, height => 600), $a);
is_deeply({$a->getDefaultSize}, {width => 300, height => 600});
