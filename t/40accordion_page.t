use Test::More tests => 6;

use IWL::Accordion::Page;

my $page = IWL::Accordion::Page->new;
is($page->appendContent(IWL::Text->new('Some text')), $page);
is($page->prependContent(IWL::Text->new('Start text')), $page);
is($page->setTitle('The title'), $page);
is($page->getTitle, 'The title');
is($page->setSelected(1), $page);
ok($page->isSelected);
