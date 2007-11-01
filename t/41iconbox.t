use Test::More tests => 2;

use IWL::Iconbox;
use IWL::Iconbox::Icon;

my $ib = IWL::Iconbox->new;
isa_ok($ib->appendIcon(IWL::Iconbox::Icon->new), 'IWL::Iconbox::Icon');
isa_ok($ib->prependIcon(IWL::Iconbox::Icon->new), 'IWL::Iconbox::Icon');
