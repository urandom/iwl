use Test::More tests => 4;

use IWL::IFrame;

{
	my $iframe = IWL::IFrame->new;
    is($iframe->set('foo.html'), $iframe);
    is($iframe->getSrc, 'foo.html');
	is($iframe->getContent, '<iframe src="foo.html"></iframe>' . "\n");
	is_deeply($iframe->getObject, {
			tag => 'iframe',
			attributes => {
				src => 'foo.html'
			}
	});
}
