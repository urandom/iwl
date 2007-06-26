use Test::More tests => 8;

use IWL::String qw(encodeURI decodeURI encodeURIComponent escape unescape escapeHTML unescapeHTML randomize);

is(encodeURI('train wreck, now!;'), 'train%20wreck,%20now!;', 'encodeURI');
is(decodeURI('train%20wreck,%20now!;'), 'train wreck, now!;', 'decodeURI');
is(encodeURIComponent('train wreck, now!;'), 'train%20wreck%2c%20now!%3b', 'encodeURIComponent');
is(escape('train wreck, сега!;'), 'train%20wreck%2C%20%u0441%u0435%u0433%u0430%21%3B');
is(unescape('train%20wreck%2C%20%u0441%u0435%u0433%u0430%21%3B'), "train wreck, \x{0441}\x{0435}\x{0433}\x{0430}!;");
is(escapeHTML('train & <wreck>, isn\'t "now"!'), 'train &amp; &lt;wreck&gt;, isn&#39;t &quot;now&quot;!', 'escapeHTML');
is(unescapeHTML('train &amp; &lt;wreck&gt;, isn&#39;t &quot;now&quot;!'), 'train & <wreck>, isn\'t "now"!', 'unescapeHTML');
like(randomize('train_wreck'), qr/^train_wreck_\d+$/, 'randomize');
