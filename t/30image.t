use Test::More tests => 5;

use IWL::Image;

use Locale::TextDomain qw(org.bloka.iwl);

{
	my $stock = IWL::Image->newFromStock('IWL_STOCK_SAVE');
	is($stock->getAlt, __('Save'));
	is($stock->getSrc, '/my/skin/darkness/tiny/save.gif');
}

{
	my $image = IWL::Image->new;
	$image->set('/foo/bar.jpg');
	$image->setAlt('Broken image');
	is($image->getSrc, '/foo/bar.jpg');
	is($image->getAlt, 'Broken image');
	like($image->getContent, qr(<img (?:(?:src="/foo/bar.jpg"|alt="Broken image")\s*){2}/>));
}
