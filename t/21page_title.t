use Test::More tests => 2;

use IWL::Page::Title;

my $title = IWL::Page::Title->new;
is($title->setText('Some title'), $title);
is($title->getText, 'Some title');
