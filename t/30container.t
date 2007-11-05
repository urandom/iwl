use Test::More tests => 3;

use IWL::Container;

{
	my $div = IWL::Container->new(id => 'foo');
	my $span = IWL::Container->new(inline => 1, class => 'bar');
	is($div->getContent, '<div id="foo"></div>' . "\n");
	is($span->getContent, '<span class="bar"></span>' . "\n");
	is_deeply($div->getObject, {
			tag => 'div',
			attributes => {
				id => 'foo'
			}
	});
}
