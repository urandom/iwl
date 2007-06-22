use Test::More tests => 2;

use IWL::RPC;

{
	my $rpc = IWL::RPC->new;

	$ENV{REQUEST_METHOD} = 'get';
	$ENV{QUERY_STRING} = 'foo=1&bar=baz&alpha=echo%201';
	my %params = $rpc->getParams;
	is_deeply(\%params, {
			foo => 1,
			bar => 'baz',
			alpha => 'echo 1',
	});
}

{
	my $rpc = IWL::RPC->new;
	$ENV{QUERY_STRING} = "IWLEvent=%7B%22eventName%22%3A%20%22IWL-Anchor-click%22%2C%20%22params%22%3A%20%7B%22method%22%3A%20%22_expandResponse%22%2C%20%22userData%22%3A%20%7B%22jijii%22%3A%201%7D%2C%20%22path%22%3A%20%22%5B4%5D%22%2C%20%22all%22%3A%20false%7D%7D";
	$ENV{REQUEST_METHOD} = 'get';

	$rpc->handleEvent(
		'IWL-Anchor-click',
		sub {
			my $params = shift;

			is_deeply($params, {jijii => 1});
		}
	);
}
