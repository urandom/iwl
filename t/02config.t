use Test::More tests => 3;

use IWL::Config '%IWLConfig';
ok(%IWLConfig);
is_deeply(\%IWLConfig, {
	SKIN         => 'darkness',
	SKIN_DIR     => '/my/skin/darkness',
	IMAGE_DIR    => '/my/skin/darkness/images',
	ICON_DIR     => '/my/skin/darkness/tiny',
	ICON_EXT     => 'gif',
	JS_DIR       => '/jscript',
	STRICT_LEVEL => 1,
    DEBUG        => '',
    JS_WHITELIST => [qw(SKIN SKIN_DIR IMAGE_DIR ICON_DIR ICON_EXT JS_DIR STRICT_LEVEL DEBUG)],
});
$IWLConfig{JS_WHITELIST} = ['SKIN'];
is(IWL::Config::getJSConfig, q|if (!window.IWL) var IWL = {};IWL.Config = {"SKIN": "darkness"};|);
