use Test::More tests => 2;

use IWL::Config '%IWLConfig';
ok(%IWLConfig);
is_deeply(\%IWLConfig, {
	SKIN         => 'darkness',
	SKIN_DIR     => '/my/skin/darkness',
	IMAGE_DIR    => '/my/skin/darkness/images',
	ICON_DIR     => '/my/skin/darkness/tiny',
	ICON_EXT     => 'gif',
	JS_DIR       => '/jscript',
	STRICT_LEVEL => 2,
    DEBUG        => '',
    JS_WHITELIST => [qw(SKIN SKIN_DIR IMAGE_DIR ICON_DIR ICON_EXT JS_DIR STRICT_LEVEL DEBUG)],
});
