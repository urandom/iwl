use Test::More tests => 4;

use IWL::Stock;

use Locale::TextDomain qw(org.bloka.iwl);

my $stock = IWL::Stock->new;
is($stock->getSmallImage('IWL_STOCK_OK'), '/my/skin/darkness/tiny/ok.gif');
is($stock->getLabel('IWL_STOCK_REFRESH'), __('Refresh'));
ok($stock->exists('IWL_STOCK_SAVE'));
ok(!$stock->exists('IWL_STOCK_REVERT'));
