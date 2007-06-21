use Test::More tests => 5;

use IWL::Style;

my $style = IWL::Style->new;
is($style->setMedia('screen'), $style);
is($style->getMedia, 'screen');
is($style->appendStyleImport('foo.css'), $style);
is($style->appendStyle('body { display:none;}'), $style);
like($style->getContent, qr(^<style (?:(?:media="screen"|type="text/css")\s*){2}>\@import "foo.css";\nbody { display:none;}</style>\n$));
