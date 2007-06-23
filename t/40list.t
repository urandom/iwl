use Test::More tests => 15;

use IWL::List;
use IWL::Label;

{
	my $list = IWL::List->new;

	isa_ok($list->appendListItem(IWL::Label->new->setText('foo')), 'IWL::Widget');
	isa_ok($list->prependListItem(IWL::Label->new->setText('alpha')), 'IWL::Widget');
	isa_ok($list->prependListItemText('test'), 'IWL::Widget');
	isa_ok($list->appendListItemText('baz'), 'IWL::Widget');

	like($list->getContent, qr(^<ul (?:(?:class="(list_unordered)"|id="\1_\d+")\s*){2}><li class="\1_item">test</li>\n<li class="\1_item"><span id="label_\d+">alpha</span>\n</li>\n<li class="\1_item"><span id="label_\d+">foo</span>\n</li>\n<li class="\1_item">baz</li>\n</ul>\n$)); #"
}

{
	my $list = IWL::List->new(type => 'ordered');

	isa_ok($list->appendListItem(IWL::Label->new->setText('foo')), 'IWL::Widget');
	isa_ok($list->prependListItem(IWL::Label->new->setText('alpha')), 'IWL::Widget');
	isa_ok($list->prependListItemText('test'), 'IWL::Widget');
	isa_ok($list->appendListItemText('baz'), 'IWL::Widget');

	like($list->getContent, qr(^<ol (?:(?:class="(list_ordered)"|id="\1_\d+")\s*){2}><li class="\1_item">test</li>\n<li class="\1_item"><span id="label_\d+">alpha</span>\n</li>\n<li class="\1_item"><span id="label_\d+">foo</span>\n</li>\n<li class="\1_item">baz</li>\n</ol>\n$)); #"
}

{
	my $list = IWL::List->new(type => 'definition');

	isa_ok($list->appendDefText('foo', 'key'), 'IWL::Widget');
	isa_ok($list->appendDefText('bar', 'value'), 'IWL::Widget');
	isa_ok($list->prependDefText('beta', 'value'), 'IWL::Widget');
	isa_ok($list->prependDefText('alpha', 'key'), 'IWL::Widget');

	like($list->getContent, qr(^<dl (?:(?:class="(list_definition)"|id="\1_\d+")\s*){2}><dt class="\1_key">alpha</dt>\n<dd class="\1_value">beta</dd>\n<dt class="\1_key">foo</dt>\n<dd class="\1_value">bar</dd>\n</dl>\n$)); #"
}
