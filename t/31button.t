use Test::More tests => 4;

use IWL::Button;

{
	my $button = IWL::Button->newFromStock('IWL_STOCK_SAVE', id => 'foo');
    is($button->getId, 'foo');
    is($button->getAlt, 'Save');

    is($button->getSrc, '/my/skin/darkness/tiny/save.gif');
    is($button->getTitle, 'Save');
}
