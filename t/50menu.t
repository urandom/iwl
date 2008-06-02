use Test::More tests => 9;

use IWL::Menu;

my $m = IWL::Menu->new;

isa_ok($m->appendMenuItem('Some text'), 'IWL::Menu::Item');
isa_ok($m->prependMenuItem('First item', 'IWL_STOCK_SAVE'), 'IWL::Menu::Item');
ok($m->appendMenuSeparator);
ok($m->prependMenuSeparator);
ok(!$m->bindToWidget(IWL::Widget->new, 'click'));
is($m->bindToWidget(IWL::Widget->new(id => 'foo'), 'click'), $m);
is($m->setMaxHeight(450), $m);
is($m->getMaxHeight, 450);
like($m->getContent, qr(^<ul (?:(?:class="(menu)"|id="(\1_\d+)")\s*){2}><li (?:(?:class="\1_separator"|id="\1_item_\d+")\s*){2}>&nbsp;</li>
<li (?:(?:class="\1_item"|id="\1_item_\d+"|style="background-image: url.'/my/skin/darkness/tiny/save.gif'.")\s*){3}><span (?:(?:class="\1_item_label"|id="\1_item_\d+_label")\s*){2}>First item</span>
</li>
<li (?:(?:class="\1_item"|id="\1_item_\d+")\s*){2}><span (?:(?:class="\1_item_label"|id="\1_item_\d+_label")\s*){2}>Some text</span>
</li>
<li (?:(?:class="\1_separator"|id="\1_item_\d+")\s*){2}>&nbsp;</li>
<script.*dist/prototype.js.*prototype_extensions.js.*dist/effects.js.*scriptaculous_extensions.js.*base.js.*menu.js.*?</script>
<script.*?IWL.Menu.create.'\2'.*?</script>
</ul>
$)s);
