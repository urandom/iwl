use Test::More tests => 4;

use IWL::Anchor;

my $anchor = IWL::Anchor->new;

is($anchor->setHref('iwl_demo.pl'), $anchor);
is($anchor->setTarget('_blank'), $anchor);
is($anchor->setText('Some link'), $anchor);
is($anchor->getContent, '<a target="_blank" href="iwl_demo.pl">Some link</a>' . "\n");
