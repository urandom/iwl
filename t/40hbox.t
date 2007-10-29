use Test::More tests => 5;

use IWL::HBox;

my $hbox = IWL::HBox->new(id => 'foo');
isa_ok($hbox->packStart(undef, '2px'), 'IWL::Container');
is($hbox->packStart->getClass, 'hbox_start');
isa_ok($hbox->packEnd(undef, '3px 1px'), 'IWL::Container');
is($hbox->packEnd->getClass, 'hbox_end');
like($hbox->getContent, qr(^<div id="foo"><div (?:(?:class="hbox_start"|style="margin: 2px")\s*){2}></div>\n<div class="hbox_start"></div>\n<div (?:(?:class="hbox_end"|style="margin: 3px 1px")\s*){2}></div>\n<div class="hbox_end"></div>\n</div>\n<span style="clear: both"></span>\n$));
