use Test::More tests => 5;

use IWL::PageControl;
$ENV{LANG} = $ENV{LANGUAGE} = "C";

my $pc = IWL::PageControl->new;
my $con = IWL::Container->new;
is($pc->bindToWidget($con, 'iwl_demo.pl', {foo => 'bar'}), undef);
ok(!$pc->isBound);
$con->setId('bar');
is($pc->bindToWidget($con, 'iwl_demo.pl', {foo => 'bar'}), $pc);
ok($pc->isBound);
like($pc->getContent, qr(^<script.*dist/prototype.js.*prototype_extensions.js.*dist/builder.js.*dist/effects.js.*dist/controls.js.*scriptaculous_extensions.js.*base.js.*pagecontrol.js.*?</script>
<div (?:(?:class="(pagecontrol)"|id="(\1_\d+)"|style="display: none; ")\s*){3}><script.*?button.js.*?</script>
<noscript (?:(?:class="button_noscript \1_first"|id="\2_first_noscript")\s*){2}></noscript>
<script .*?Button.create.'\2_first',.*?</script>
<noscript (?:(?:class="button_noscript \1_prev"|id="\2_prev_noscript")\s*){2}></noscript>
<script .*?Button.create.'\2_prev',.*?</script>
<span (?:(?:class="\1_label"|id="\2_label")\s*){2}><span (?:(?:class="entry \1_page_entry"|id="\2_page_entry")\s*){2}><input (?:(?:class="entry_text"|id="\2_page_entry_text"|type="text"|size="2")\s*){4}/>
</span>
 of <span (?:(?:class="\1_page_count"|id="\2_page_count")\s*){2}></span>
</span>
<noscript (?:(?:class="button_noscript \1_next"|id="\2_next_noscript")\s*){2}></noscript>
<script .*?Button.create.'\2_next',.*?</script>
<noscript (?:(?:class="button_noscript \1_last"|id="\2_last_noscript")\s*){2}></noscript>
<script .*?Button.create.'\2_last',.*?</script>
</div>
<script.*?PageControl.create.'\2'.*?bindToWidget.'bar', 'IWL-Container-refresh'.;</script>
$)s);
