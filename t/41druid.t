use Test::More tests => 5;

use IWL::Druid;
use IWL::Label;

my $druid = IWL::Druid->new;
my $page;
isa_ok($druid->appendPage(IWL::Label->new->setText('Some text')), 'IWL::Druid::Page');
isa_ok($druid->prependPage(IWL::Label->new->setText('First page')), 'IWL::Druid::Page');
is($page = $druid->appendPage(IWL::Label->new->setText('Last page'), 'alert', 'this', 1), $page);
is($druid->showFinish($page), $druid);
like($druid->getContent, qr(.*dist/prototype.js.*prototype_extensions.js.*dist/builder.js.*dist/effects.js.*dist/controls.js.*scriptaculous_extensions.js.*base.js.*druid.js.*?
<div (?:(?:class="(druid)"|id="\1_\d+")\s*){2}><div (?:(?:class="\1_content"|id="\1_\d+_content")\s*){2}><div (?:(?:class="\1_page"|id="\1_page_\d+")\s*){2}><span id="label_\d+">First page</span>
</div>
<div (?:(?:class="\1_page"|id="\1_page_\d+")\s*){2}><span id="label_\d+">Some text</span>
</div>
<div (?:(?:iwl:druidCheckCallback="alert"|class="\1_page \1_page_selected"|iwl:druidCheckParam="\[%22this%22\]"|iwl:druidLastPage="1"|id="\1_page_\d+")\s*){5}><span id="label_\d+">Last page</span>
</div>
</div>
<div (?:(?:class="\1_button_container"|id="\1_\d+_button_container")\s*){2}><script .*button.js.*?</script>
<noscript.*?</noscript>
<script.*?Button.create.*?</script>
<noscript.*?</noscript>
<script.*?Button.create.*?</script>
</div>
<br style="clear: both; " />
</div>
<script.*?Druid.create.*?</script>
$)s);
