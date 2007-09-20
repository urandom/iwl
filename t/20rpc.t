use Test::More tests => 3;

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
	my $content = 'foo=1&bar=baz&alpha=echo%201';

	$ENV{REQUEST_METHOD} = 'post';
	$ENV{CONTENT_LENGTH} = length $content;

	tie *STDIN, 'READ_TEST', $content;

	my %params = $rpc->getParams;

	untie *STDIN;

	is_deeply(\%params, {
			foo => 1,
			bar => 'baz',
			alpha => 'echo 1',
	});
}

{
	my $rpc = IWL::RPC->new;
	$ENV{QUERY_STRING} = "IWLEvent=%7B%22eventName%22%3A%20%22IWL-Anchor-click%22%2C%20%22params%22%3A%20%7B%22param_test%22%3A%201%7D%2C%20%22options%22%3A%20%7B%7D%7D";
	$ENV{REQUEST_METHOD} = 'get';

	$rpc->handleEvent(
		'IWL-Anchor-click',
		sub {
			my $params = shift;

			is_deeply($params, {param_test => 1});
		}
	);
}

package READ_TEST;

sub TIEHANDLE {
	my $self = {};
	bless $self, shift;
	$self->{_content} = shift;

	return $self;
}

sub READ {
	my $self = shift;
	$_[0] = $self->{_content};
}
