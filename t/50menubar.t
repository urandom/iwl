use Test::More tests => 6;

use IWL::Menubar;

my $m = IWL::Menubar->new;

isa_ok($m->appendMenuItem('Some text'), 'IWL::Menu::Item');
isa_ok($m->prependMenuItem('First item', 'IWL_STOCK_SAVE'), 'IWL::Menu::Item');
ok($m->appendMenuSeparator);
ok($m->prependMenuSeparator);
is($m->setMouseOverActivation(1), $m);
ok($m->getMouseOverActivation);
