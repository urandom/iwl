use Test::More tests => 5;

use IWL::HBox;

my $hbox = IWL::HBox->new(id => 'foo');
isa_ok($hbox->packStart(undef, '2px'), 'IWL::Container');
is($hbox->packStart->{_defaultClass}, 'hbox_start');
isa_ok($hbox->packEnd(undef, '3px 1px'), 'IWL::Container');
is($hbox->packEnd->{_defaultClass}, 'hbox_end');
like($hbox->getContent, qr(^<div (?:(?:class="hbox"|id="foo")\s*){2}><div (?:(?:class="hbox_start"|style="margin: 2px")\s*){2}></div>
<div class="hbox_start"></div>
<div (?:(?:class="hbox_end"|style="margin: 3px 1px")\s*){2}></div>
<div class="hbox_end"></div>
</div>
<span style="clear: both"></span>
$));
