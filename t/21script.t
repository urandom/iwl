use Test::More tests => 1;

use IWL::Script;

{
	my $script = IWL::Script->new;

	$script->setSrc('/foo/bar.js');
	is($script->getContent, '<script src="/foo/bar.js" type="text/javascript"></script>' . "\n");
}
