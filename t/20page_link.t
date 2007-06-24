use Test::More tests => 4;

use IWL::Page::Link;

{
	my $link = IWL::Page::Link->new;
	ok($link->setHref('iwl_demo.pl'), $link);
	ok($link->getHref, 'iwl_demo.pl');
}

{
	isa_ok(my $css = IWL::Page::Link->newLinkToCSS('main.css', 'sheet'), 'IWL::Page::Link');
	like($css->getContent, qr(^<link (?:(?:type="text/css"|rel="stylesheet"|href="main.css"|media="sheet")\s*){4}/>\n$));
}
