use Test::More tests => 7;

use IWL::Script;
use IWL::Config '%IWLConfig';

{
	my $script = IWL::Script->new;

	$script->setSrc('/foo/bar.js');
    is($script->getAttribute('src'), '/foo/bar.js');
    is($script->getSrc, '/foo/bar.js');
    is($script->getAttribute('type'), 'text/javascript');
    like($script->getContent, qr(<script (?:\w+=".*?(?<!\\)"\s*){2}></script>));
}

{
	my $script = IWL::Script->new;

	$script->appendScript('alert(1)');
	$script->prependScript('console.log(this)');
	$script->appendScript('window.close()');

	is($script->getScript, 'console.log(this); alert(1); window.close();');

	$script->setScript('console.debug(1)');
	is($script->getScript, 'console.debug(1);');

    $IWLConfig{STRICT_LEVEL} = 2;
	is($script->getScript, "\n//<![CDATA[\nconsole.debug(1);\n//]]>");
}
