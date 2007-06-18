use Test::More tests => 2;

use IWL::Break;

my $break = IWL::Break->new;

is($break->getContent, "<br />\n");
is_deeply($break->getObject, {tag => 'br'});
