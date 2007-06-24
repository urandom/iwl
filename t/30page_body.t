use Test::More tests => 1;

use IWL::Page::Body;

my $body = IWL::Page::Body->new;
is($body->signalConnect(unload => "alert('1')"), $body);
