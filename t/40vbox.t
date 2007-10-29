use Test::More tests => 5;

use IWL::VBox;

my $vbox = IWL::VBox->new(id => 'foo');
is($vbox->packEnd(undef, '5px')->{_defaultClass}, 'vbox_end');
isa_ok($vbox->packStart(undef, '2px'), 'IWL::Container');
is($vbox->packStart(undef, '2px 3px')->{_defaultClass}, 'vbox_start');
isa_ok($vbox->packEnd(undef, '3px 1px'), 'IWL::Container');
like($vbox->getContent, qr(^<div (?:(?:class="vbox"|id="foo")\s*){2}><div (?:(?:class="vbox_start"|style="margin: 2px")\s*){2}></div>
<div (?:(?:class="vbox_start"|style="margin: 2px 3px")\s*){2}></div>
<div (?:(?:class="vbox_end"|style="margin: 3px 1px")\s*){2}></div>
<div (?:(?:class="vbox_end"|style="margin: 5px")\s*){2}></div>
</div>
$));
