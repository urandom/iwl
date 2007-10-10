use Test::More tests => 7;

use IWL::Druid::Page;

my $page = IWL::Druid::Page->new;
is($page->setFinal(1), $page);
ok($page->isFinal);
is($page->setSelected(1), $page);
ok($page->isSelected);
is($page->setCheckCB('alert', 'this'), $page);
is($page->appendChild(IWL::Text->new("Some text")), $page);
like($page->getContent, qr(<div (?:(?:iwl:druidCheckCallback="alert"|class="druid_page druid_page_selected"|iwl:druidCheckParam="\[%22this%22,0\]"|iwl:druidFinalPage="1"|id="druid_page_\d+")\s*){5}>Some text</div>\n));
