use Test::More tests => 1;

use IWL::Page::Head;

isa_ok(IWL::Page::Head->new, 'IWL::Page::Head');
