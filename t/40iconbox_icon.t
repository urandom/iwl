use Test::More tests => 9;

use IWL::Iconbox::Icon;

my $icon = IWL::Iconbox::Icon->new;

is($icon->setImage('/foo/bar.jpg'), $icon); 
is($icon->setImage('/foo/alpha.jpg', 'Alt text'), $icon); 
is($icon->getImage, $icon->{image});
is($icon->getImage->getAlt, 'Alt text');
is($icon->setText('Some text'), $icon);
is($icon->getText, 'Some text');
is($icon->setSelected(1), $icon);
ok($icon->isSelected);
like($icon->getContent, qr(^<div (?:(?:class="(icon)"|id="(\1_\d+)")\s*){2}><img (?:(?:alt="Alt text"|src="/foo/alpha.jpg"|id="\2_image"|onload=".*?")\s*){4}/>
<p (?:(?:class="\1_label"|id="\2_label")\s*){2}>Some text</p>
</div>
$)s);
