use Test::More tests => 12;

use IWL::Menu::Item;
use IWL::Menu;

my $mi = IWL::Menu::Item->new;
is($mi->setText('Some text'), $mi);
is($mi->getText, 'Some text');
is($mi->setIcon('IWL_STOCK_SAVE'), $mi);
is($mi->setType('bla'), undef);
is($mi->setType('check'), $mi);
is($mi->getType, 'check');
my $sub = IWL::Menu->new;
is($mi->setSubmenu($sub), $sub);
is($mi->getSubmenu, $sub);
is($mi->toggle(1), $mi);
is($mi->setDisabled(1), $mi);
ok($mi->isDisabled);
like($mi->getContent, qr(^<li (?:(?:class="(menu_item) \1_disabled menu_check_item menu_check_item_checked"|id="\1_\d+"|style="background-image: url.'/my/skin/darkness/tiny/save.gif'.")\s*){3}><span (?:(?:class="menu_item_label menu_item_label_parent"|id="menu_item_\d+_label")\s*){2}>Some text</span>
<script.*dist/prototype.js.*prototype_extensions.js.*dist/effects.js.*dist/controls.js.*scriptaculous_extensions.js.*base.js.*menu.js.*?</script>
<ul (?:(?:class="menu submenu"|id="(menu_\d+)")\s*){2}></ul>
)s);
