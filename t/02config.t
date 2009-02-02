use Test::More tests => 7;

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
    TEXT_DOMAIN  => 'org.bloka.iwl',
    JS_WHITELIST => [qw(SKIN SKIN_DIR IMAGE_DIR ICON_DIR ICON_EXT JS_DIR STRICT_LEVEL DEBUG)],
});
$IWLConfig{JS_WHITELIST} = ['SKIN'];
is(IWL::Config::getJSConfig, q|if (!window.IWL) var IWL = {};IWL.Config = {"SKIN": "darkness"};|);

# Will not work if the locale is not installed
SKIP: {
    skip "Skipping due to possible missing bg locale", 4;

    use Locale::TextDomain $IWLConfig{TEXT_DOMAIN};
    $ENV{LANG} = $ENV{LANGUAGE} = 'C';
    is(__('Refresh'), 'Refresh');
    is(__('Save'), 'Save');
    $ENV{LANG} = $ENV{LANGUAGE} = 'bg';
    is(__('Refresh'), 'Обновяване');
    is(__('Save'), 'Запазване');
}
