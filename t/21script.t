use Test::More tests => 3;

use IWL::Script;

{
	my $script = IWL::Script->new;

	$script->setSrc('/foo/bar.js');
	is($script->getContent, '<script src="/foo/bar.js" type="text/javascript"></script>' . "\n");
}

{
	my $script = IWL::Script->new;

	$script->appendScript('alert(1)');
	$script->prependScript('console.log(this)');
	$script->appendScript('window.close()');

	is($script->getScript, 'console.log(this);alert(1);window.close();');

	$script->setScript('console.debug(1)');
	is($script->getScript, 'console.debug(1);');
}
