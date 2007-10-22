use Test::More tests => 6;

use IWL::Upload;


my $up = IWL::Upload->new;
is($up->setAccept('*.pl'), $up);
is($up->getAccept, '*.pl');
is($up->setLabel('Some label'), $up);
is($up->getLabel, 'Some label');
is($up->setUploadCallback('alert'), $up);
like($up->getContent, qr(^<script.*dist/prototype.js.*prototype_extensions.js.*dist/effects.js.*dist/controls.js.*scriptaculous_extensions.js.*base.js.*upload.js.*tooltip.js.*?</script>
<form (?:(?:target="((upload)_\d+)_frame"|enctype="multipart/form-data"|class="\2"|id="\1"|method="post")\s*){5}><iframe (?:(?:class="\2_frame"|id="\1_frame"|name="\1_frame")\s*){3}></iframe>
<script.*?button.js.*?</script>
<noscript (?:(?:class="button_noscript \2_button"|id="\1_button_noscript")\s*){2}></noscript>
<script .*?IWL.Button.create.'\1_button',.*?IWL.Upload.create.'\1',.*?</script>
</form>
$)s);
