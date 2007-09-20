use Test::More tests => 15;

use IWL::Contentbox;
use IWL::Label;
use IWL::Anchor;
use IWL::Break;

my $cb = IWL::Contentbox->new(id => 'cb');
is($cb->appendTitle(IWL::Label->new->setText("Foo bar\n")), $cb);
is($cb->appendTitleText('Alpha'), $cb);
is($cb->appendHeaderText('Some text'), $cb);
is($cb->appendHeader(IWL::Break->new), $cb);
is($cb->appendContent(IWL::Anchor->new->setText("A link")), $cb);
is($cb->appendContentText('Content text'), $cb);
is($cb->appendFooter(IWL::Anchor->new->setText("Another link")), $cb);
is($cb->appendFooterText('Footer text'), $cb);

is($cb->setType('noresize'), $cb);
is($cb->setHeaderColorType(2), $cb);
is($cb->setFooterColorType(0), $cb);
is($cb->setShadows(1), $cb);
is($cb->setAutoWidth(1), $cb);
is($cb->setTitleImage, $cb);

like($cb->getContent, qr(.*dist/prototype.js.*prototype_extensions.js.*dist/effects.js.*dist/controls.js.*scriptaculous_extensions.js.*base.js.*dist/dragdrop.js.*dist/resizer.js.*contentbox.js.*?
<div (?:(?:class="contentbox shadowbox"|id="cb")\s*){2}><div (?:(?:class="contentbox_top"|id="cb_top")\s*){2}><div (?:(?:class="contentbox_topr"|id="cb_topr")\s*){2}></div>
</div>
<div (?:(?:class="contentbox_title"|id="cb_title"|style="cursor: move; ")\s*){3}><div (?:(?:class="contentbox_titler"|id="cb_titler"|style="cursor: move; ")\s*){3}><span id="label_\d+">Foo bar<br />
</span>
<span (?:(?:class="contentbox_title_label"|id="label_\d+")\s*){2}>Alpha</span>
</div>
</div>
<div (?:(?:class="contentbox_header contentbox_header_alt2"|id="cb_header")\s*){2}><span id="label_\d+">Some text</span>
<br />
</div>
<div (?:(?:class="contentbox_middle"|id="cb_middle")\s*){2}><div (?:(?:class="contentbox_middler"|id="cb_middler")\s*){2}><div (?:(?:class="contentbox_content"|id="cb_content")\s*){2}><a (?:(?:class="anchor"|id="anchor_\d+")\s*){2}>A link</a>
<span id="label_\d+">Content text</span>
</div>
</div>
</div>
<div (?:(?:class="contentbox_footer"|id="cb_footer")\s*){2}><div (?:(?:class="contentbox_footerr"|id="cb_footerr")\s*){2}><a (?:(?:class="anchor"|id="anchor_\d+")\s*){2}>Another link</a>
<span id="label_\d+">Footer text</span>
</div>
</div>
<div (?:(?:class="contentbox_bottom"|id="cb_bottom")\s*){2}><div (?:(?:class="contentbox_bottomr"|id="cb_bottomr")\s*){2}></div>
</div>
</div>
<script type="text/javascript">Contentbox.create.'cb', {.*}.;</script>
)s);
