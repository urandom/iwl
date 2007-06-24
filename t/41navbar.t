use Test::More tests => 6;

use IWL::NavBar;

my $navbar = IWL::NavBar->new;

isa_ok($navbar->appendPath('foo', "alert('foo')"), 'IWL::Label');
isa_ok($navbar->prependPath('tmp', "alert('tmp')"), 'IWL::Label');
isa_ok($navbar->appendOption('alpha', "beta"), 'IWL::Combo::Option');
isa_ok($navbar->prependOption('bravo', 'foxtrot'), 'IWL::Combo::Option');
is($navbar->setComboChangeCB("alert('changed')"), $navbar);
like($navbar->getContent, qr(^<div (?:(?:class="(navbar)"|id="\1_\d+")\s*){2}><span (?:(?:class="\1_crumb_con"|id="\1_\d+_crumb_con")\s*){2}><span (?:(?:class="\1_delim"|id="label_\d+")\s*){2}>/</span>\n<span (?:(?:class="\1_crumb"|onclick="alert.'tmp'."|id="label_\d+")\s*){3}>tmp</span>\n<span (?:(?:class="\1_delim"|id="label_\d+")\s*){2}>/</span>\n<span (?:(?:class="\1_crumb"|onclick="alert.'foo'."|id="label_\d+")\s*){3}>foo</span>\n</span>\n<span (?:(?:class="\1_delim"|id="label_\d+")\s*){2}>/</span>\n<select (?:(?:class="combo \1_combo"|id="\1_\d+_combo"|onchange="alert.'changed'.")\s*){3}><option value="foxtrot">bravo</option>\n<option value="beta">alpha</option>\n</select>\n</div>\n$)s);
