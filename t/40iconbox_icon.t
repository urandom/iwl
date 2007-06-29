use Test::More tests => 9;

use IWL::Iconbox::Icon;

my $icon = IWL::Iconbox::Icon->new;

is($icon->setImage('/foo/bar.jpg'), $icon); 
is($icon->setImage('IWL_STOCK_SAVE', 'Alt text'), $icon);
is($icon->getImage, $icon->{image});
is($icon->getImage->getAlt, 'Alt text');
is($icon->setText('Some text'), $icon);
is($icon->getText, 'Some text');
is($icon->setSelected(1), $icon);
ok($icon->isSelected);
like($icon->getContent, qr(^<div (?:(?:class="(icon)"|id="(\1_\d+)")\s*){2}><img (?:(?:alt="Alt text"|src="/my/skin/darkness/tiny/save.gif"|id="\2_image"|onload=".*?"|class="\1_image")\s*){5}/>
<p (?:(?:class="\1_label"|id="\2_label")\s*){2}>Some text</p>
</div>
$)s);
