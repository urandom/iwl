use Test::More tests => 18;

use IWL::Button;
use IWL::Environment;

use Locale::TextDomain qw(org.bloka.iwl);

{
	my $button = IWL::Button->newFromStock('IWL_STOCK_SAVE', id => 'foo');
    is($button->getId, 'foo');
	is($button->getAlt, __('Save'));
	isa_ok($button->getImage, 'IWL::Image');

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
    is($button->setDisabled(1), $button);
    ok($button->isDisabled);
}

{
    my $e = IWL::Environment->new;
    my ($b1, $b2) = (IWL::Button->new(environment => $e), IWL::Button->new(environment => $e));
    my ($o1, $o2) = ($b1->getObject, $b2->getObject);

    is($o1->{children}[10]{attributes}{src}, '/jscript/dist/prototype.js');
    ok(!exists $o2->{children}[10]{attributes}{src});
    ok(exists $o2->{children}[10]{attributes}{'iwl:initScript'});
}
