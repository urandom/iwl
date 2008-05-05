use Test::More tests => 5;

use IWL::NavBar;

my $navbar = IWL::NavBar->new;

isa_ok($navbar->appendPath('foo', "Foo"), 'IWL::Label');
isa_ok($navbar->prependPath('tmp', "TMP"), 'IWL::Label');
isa_ok($navbar->appendOption('alpha', "Beta"), 'IWL::Combo::Option');
isa_ok($navbar->prependOption('bravo', 'Foxtrot'), 'IWL::Combo::Option');
like($navbar->getContent, qr(^<div (?:(?:class="(navbar)"|id="\1_\d+")\s*){2}><span (?:(?:class="\1_crumb_con"|id="\1_\d+_crumb_con")\s*){2}><span (?:(?:class="\1_delim"|id="label_\d+")\s*){2}>/</span>
<span (?:(?:class="\1_crumb"|iwl:value="TMP"|id="\1_\d+_crumb_\d+")\s*){3}>tmp</span>
<span (?:(?:class="\1_delim"|id="label_\d+")\s*){2}>/</span>
<span (?:(?:class="\1_crumb"|iwl:value="Foo"|id="\1_\d+_crumb_\d+")\s*){3}>foo</span>
</span>
<span (?:(?:class="\1_delim"|id="label_\d+")\s*){2}>/</span>
<select (?:(?:class="combo \1_combo"|id="\1_\d+_combo")\s*){2}><option></option>
<option value="Foxtrot">bravo</option>
<option value="Beta">alpha</option>
</select>
.*navbar.js.*
<script.*IWL.NavBar.create.*
</div>
)s);
