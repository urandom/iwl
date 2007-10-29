use Test::More tests => 7;

use IWL::Menubar;

my $m = IWL::Menubar->new;

isa_ok($m->appendMenuItem('Some text'), 'IWL::Menu::Item');
isa_ok($m->prependMenuItem('First item', 'IWL_STOCK_SAVE'), 'IWL::Menu::Item');
ok($m->appendMenuSeparator);
ok($m->prependMenuSeparator);
is($m->setMouseOverActivation(1), $m);
ok($m->getMouseOverActivation);
like($m->getContent, qr(^<script.*dist/prototype.js.*prototype_extensions.js.*dist/effects.js.*dist/controls.js.*scriptaculous_extensions.js.*base.js.*menu.js.*?</script>
<ul (?:(?:class="(menubar)"|id="(\1_\d+)")\s*){2}><li (?:(?:class="\1_separator"|id="\1_item_\d+")\s*){2}>&nbsp;</li>
<li (?:(?:class="\1_item"|id="\1_item_\d+"|style="background-image: url.'/my/skin/darkness/tiny/save.gif'.")\s*){3}><span (?:(?:class="\1_item_label"|id="\1_item_\d+_label")\s*){2}>First item</span>
</li>
<li (?:(?:class="\1_item"|id="\1_item_\d+")\s*){2}><span (?:(?:class="\1_item_label"|id="\1_item_\d+_label")\s*){2}>Some text</span>
</li>
<li (?:(?:class="\1_separator"|id="\1_item_\d+")\s*){2}>&nbsp;</li>
</ul>
<script.*?IWL.Menu.create.'\2'.*?</script>
$)s);
