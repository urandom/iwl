use Test::More tests => 3;

use IWL::Text;

{
	my $text = IWL::Text->new('foo bar');
	is ($text->getContent, 'foo bar');
}

{
	my $text = IWL::Text->new;

	$text->appendContent('Lorem ');
	$text->appendContent('Ipsum ');
	$text->prependContent('Foobar ');
	$text->appendContent('Dolor');
	is ($text->getContent, 'Foobar Lorem Ipsum Dolor');

	$text->setContent('Alpha');
	is ($text->getContent, 'Alpha');
}
