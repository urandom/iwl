use Test::More tests => 12;

use IWL::Button;

use Locale::TextDomain qw(org.bloka.iwl);


{
	my $button = IWL::Button->newFromStock('IWL_STOCK_SAVE', id => 'foo');
    is($button->getId, 'foo');
	is($button->getAlt, __('Save'));

    is($button->getSrc, '/my/skin/darkness/tiny/save.gif');
	is($button->getTitle, __('Save'));
    is($button->setTitle("Don't save!"), $button);
    is($button->getTitle, "Don't save!");
}

{
    my $button = IWL::Button->new(id => 'foo', class => 'bar');
    is($button->setLabel('FooBar'), $button);
    is($button->getLabel, 'FooBar');
    is($button->getClass, 'bar');
    is($button->getId, 'foo');
    is($button->setHref('iwl_demo.pl'), $button);
    is($button->getHref, 'iwl_demo.pl');
}
