use Test::More tests => 8;

use IWL::Page;

{
	my $page = IWL::Page->new;
	isa_ok($page->appendMetaEquiv(foo => 'bar'), 'IWL::Page::Meta');
	is($page->appendHeader(IWL::Object->new), $page);
	is($page->prependHeader(IWL::Object->new), $page);
	is($page->setTitle('Some title'), $page);
	is($page->getTitle, 'Some title');
	is($page->setDeclaration('html401'), $page);
	is($page->getDeclaration, 'DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd"');
}

{
	my $page = IWL::Page->new(simple => 1);
	like($page->getContent, qr(^<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\s*"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html [^>]*?><head></head>\n<body></body>\n</html>\n$)s);
}
