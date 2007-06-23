use Test::More tests => 7;

use IWL::SubmitImage;

use Locale::TextDomain qw(org.bloka.iwl);

{
	my $stock = IWL::SubmitImage->newFromStock('IWL_STOCK_SAVE');
	is($stock->getAlt, __('Save'));
	is($stock->getSrc, '/my/skin/darkness/tiny/save.gif');
}

{
	my $image = IWL::SubmitImage->new;
	$image->setName('foo');
	$image->setValue('bar');
	$image->set('/foo/bar.jpg');
	$image->setAlt('Broken image');
	is($image->getSrc, '/foo/bar.jpg');
	is($image->getAlt, 'Broken image');
	is($image->getName, 'foo');
	is($image->getValue, 'bar');
	like($image->getContent, qr(^<input (?:(?:src="/foo/bar.jpg"|alt="Broken image"|type="image"|name="foo"|value="bar"|id="image_\d+"|class="image")\s*){7}/>$));
}
