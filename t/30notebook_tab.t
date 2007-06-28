use Test::More tests => 7;

use IWL::Notebook::Tab;

my $tab = IWL::Notebook::Tab->new;
is($tab->appendPage(IWL::Anchor->new->setText('Some text')), $tab);
is($tab->prependPage(IWL::Anchor->new->setText('Start text')), $tab);
is($tab->setTitle('The title'), $tab);
is($tab->getTitle, 'The title');
is($tab->setSelected(1), $tab);
ok($tab->isSelected);
like($tab->getContent, qr(^<li (?:(?:class="(notebook_tab) notebook_tab_selected"|id="\1_\d+")\s*){2}><a (?:(?:class="anchor \1_anchor"|id="\1_\d+_anchor")\s*){2}>The title</a>
</li>
$)s);
