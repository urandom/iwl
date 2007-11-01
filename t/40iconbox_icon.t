use Test::More tests => 8;

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
