use Test::More tests => 10;

use IWL::Button;

{
	my $button = IWL::Button->newFromStock('IWL_STOCK_SAVE', id => 'foo');
    is($button->getId, 'foo');
    is($button->getAlt, 'Save');

    is($button->getSrc, '/my/skin/darkness/tiny/save.gif');
    is($button->getTitle, 'Save');
    is($button->setTitle("Don't save!"), $button);
    is($button->getTitle, "Don't save!");
}

{
    my $button = IWL::Button->new(id => 'foo', class => 'bar');
    is($button->setLabel('FooBar'), $button);
    is($button->getLabel, 'FooBar');
    is($button->getClass, 'bar');
    is($button->getId, 'foo');
}
