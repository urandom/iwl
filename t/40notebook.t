use Test::More tests => 3;

use IWL::Notebook;

my $nb = IWL::Notebook->new;
isa_ok($nb->appendTab('Future tab'), 'IWL::Notebook::Tab');
isa_ok($nb->prependTab('First tab', IWL::Label->new->setText('First text')), 'IWL::Notebook::Tab');
like($nb->getContent, qr(.*dist/prototype.js.*prototype_extensions.js.*dist/builder.js.*dist/effects.js.*dist/controls.js.*scriptaculous_extensions.js.*base.js.*notebook.js.*?
<div (?:(?:class="(notebook)"|id="(\1_\d+)")\s*){2}><div (?:(?:class="\1_navgroup"|id="\2_navgroup")\s*){2}><ul (?:(?:class="list_unordered \1_mainnav"|id="\2_mainnav")\s*){2}><li (?:(?:class="\1_tab \1_tab_selected"|id="\1_tab_\d+")\s*){2}><a (?:(?:class="anchor \1_tab_anchor"|id="\1_tab_\d+_anchor")\s*){2}>First tab</a>
</li>
<li (?:(?:class="\1_tab"|id="\1_tab_\d+")\s*){2}><a (?:(?:class="anchor \1_tab_anchor"|id="\1_tab_\d+_anchor")\s*){2}>Future tab</a>
</li>
</ul>
<br (?:(?:class="\1_clear"|id="\2_clear")\s*){2}/>
</div>
<div (?:(?:class="\1_navborder"|id="\2_navborder")\s*){2}></div>
<div (?:(?:class="\1_content"|id="\2_content")\s*){2}><div (?:(?:class="\1_page \1_page_selected"|id="\1_page_\d+")\s*){2}><span id="label_\d+">First text</span>
</div>
<div (?:(?:class="\1_page"|id="\1_page_\d+")\s*){2}></div>
</div>
</div>
<script.*Notebook.create.'\2'.;</script>
$)s);
