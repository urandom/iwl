use Test::More tests => 7;

use IWL::TextEditor;
use IWL::Container;

{
	my $t = IWL::TextEditor->new;
    my $p = IWL::Container->new(id => 'foo');

    ok(!$t->getPanel);
    is($t->setPanel('foobar'), $t);
    is($t->getPanel, 'foobar');
    is($t->setPanel, $t);
    ok(!$t->getPanel);
    is($t->setPanel($p), $t);
    is($t->getPanel, $p);
}
