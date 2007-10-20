use Test::More tests => 3;

use IWL::Iconbox;
use IWL::Iconbox::Icon;

my $ib = IWL::Iconbox->new;
isa_ok($ib->appendIcon(IWL::Iconbox::Icon->new), 'IWL::Iconbox::Icon');
isa_ok($ib->prependIcon(IWL::Iconbox::Icon->new), 'IWL::Iconbox::Icon');
like($ib->getContent, qr(.*dist/prototype.js.*prototype_extensions.js.*dist/effects.js.*dist/controls.js.*scriptaculous_extensions.js.*base.js.*iconbox.js.*?
<div (?:(?:class="(iconbox)"|id="(\1_\d+)")\s*){2}><div (?:(?:class="\1_icon_container"|id="\2_icon_container"|style="overflow: auto; ")\s*){3}><div (?:(?:class="icon \1_icon"|id="icon_\d+")\s*){2}><img (?:(?:onload=".*?"|class="icon_image"|id="icon_\d+_image")\s*){3}/>
</div>
</div>
<div (?:(?:class="\1_status_label"|id="\2_status_label")\s*){2}></div>
</div>
<script.*?IWL.Iconbox.create.'\2'.*?</script>
$)s);
