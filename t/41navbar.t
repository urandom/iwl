use Test::More tests => 6;

use IWL::NavBar;

my $navbar = IWL::NavBar->new;

isa_ok($navbar->appendPath('foo', "alert('foo')"), 'IWL::Label');
isa_ok($navbar->prependPath('tmp', "alert('tmp')"), 'IWL::Label');
isa_ok($navbar->appendOption('alpha', "beta"), 'IWL::Combo::Option');
isa_ok($navbar->prependOption('bravo', 'foxtrot'), 'IWL::Combo::Option');
is($navbar->setComboChangeCB("alert('changed')"), $navbar);
like($navbar->getContent, qr(^<div (?:(?:class="(navbar)"|id="\1_\d+")\s*){2}><span (?:(?:class="\1_crumb_con"|id="\1_\d+_crumb_con")\s*){2}><span (?:(?:class="\1_delim"|id="label_\d+")\s*){2}>/</span>
<span (?:(?:class="\1_crumb"|onclick="alert.&#39;tmp&#39;.*selectedIndex = 0[^"]*"|id="label_\d+")\s*){3}>tmp</span>
<span (?:(?:class="\1_delim"|id="label_\d+")\s*){2}>/</span>
<span (?:(?:class="\1_crumb"|onclick="alert.&#39;foo&#39;.*selectedIndex = 0[^"]*"|id="label_\d+")\s*){3}>foo</span>
</span>
<span (?:(?:class="\1_delim"|id="label_\d+")\s*){2}>/</span>
<select (?:(?:class="combo \1_combo"|id="\1_\d+_combo"|onchange="alert.&#39;changed&#39;.")\s*){3}><option></option>
<option value="foxtrot">bravo</option>
<option value="beta">alpha</option>
</select>
</div>
)s);
