use Test::More tests => 5;

use IWL::Anchor;

my $anchor = IWL::Anchor->new;

is($anchor->setHref('iwl_demo.pl'), $anchor);
is($anchor->setTarget('_blank'), $anchor);
is($anchor->setText('Some link'), $anchor);
like($anchor->getContent, qr/<a (?:(?:target="_blank"|href="iwl_demo.pl")\s*){2}>Some link<\/a>/);
is_deeply($anchor->getObject, {
        tag => 'a',
        children => [
            { text => 'Some link' }
        ],
        attributes => {
            target => '_blank',
            href => 'iwl_demo.pl'
        }
});
