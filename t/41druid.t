use Test::More tests => 1;

use IWL::Druid;

my $druid = IWL::Druid->new;
isa_ok($druid->appendPage(IWL::Label->new->setText('Some text')), 'IWL::Druid::Page');
