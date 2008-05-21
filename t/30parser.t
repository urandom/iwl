use Test::More tests => 8;

use IWL::Parser;

{
	my $parser = IWL::Parser->new;
	isa_ok(my $object = $parser->createObjectFromFile('t/test.html'), 'IWL::Object');
	like($object->getContent, qr(^<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html (?:(?:xmlns="http://www.w3c.org/1999/xhtml"|xmlns:iwl="http://namespace.bloka.org/iwl")\s*){2}>\s*<head>\s*<script type="text/javascript">window.IWLConfig =.*?;</script>\s*<link (?:(?:rel="stylesheet"|href="/iwl/skin/default/main.css"|media="screen"|type="text/css"|title="Main")\s*){5}/>\s*<!--.*?-->\s*<title>Tree Test</title>\s*</head>\s*<body>\s*<a href="test.html#">Some anchor</a>\s*</body>\s*</html>$)s);
}

{
	my $parser = IWL::Parser->new;
	my $html = <<EOF;
	<div id="1">
		<a href="bla">Foo</a>
	</div>
    <? iwl {
        package: "IWL::Label",
        methods: [
            {setText: "Foo"}
        ]
      } >
	<div id="2">Bar</div>
EOF
	my ($div1, $span, $div2) = $parser->createObject($html);

	isa_ok($div1, 'IWL::Object');
	isa_ok($span, 'IWL::Label');
	isa_ok($div2, 'IWL::Object');
	like($div1->getContent, qr(^<div id="1">\s*<a href="bla">Foo</a>\s*</div>$)s);
	like($span->getContent, qr(^<span id="label_\d+">\s*Foo\s*</span>$)s);
	like($div2->getContent, qr(^<div id="2">Bar</div>\n$));
}
