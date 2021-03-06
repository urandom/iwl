use Test::More tests => 7;

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
	like($image->getContent, qr(^<img (?:(?:src="/foo/bar.jpg"|alt="Broken image"|class="image"|id="image_\d+")\s*){4}/>$));
}

{
	my $image = IWL::Image->new;
	$image->set('/foo/bar_baz.jpg');
	ok(!$image->getAlt);
	like($image->getContent, qr(^<img (?:(?:src="/foo/bar_baz.jpg"|alt="bar baz"|class="image"|id="image_\d+")\s*){4}/>$));
}
