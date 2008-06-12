use Test::More tests => 6;

use IWL::PageControl;

my $pc = IWL::PageControl->new;
my $con = IWL::Container->new;
is($pc->setPageOptions(page => 11, pageSize => 15), $pc);
is_deeply({$pc->getPageOptions}, {page => 11, pageSize => 15});
is($pc->bindToWidget($con, 'iwl_demo.pl', {foo => 'bar'}), undef);
ok(!$pc->isBound);
$con->setId('bar');
is($pc->bindToWidget($con, 'iwl_demo.pl', {foo => 'bar'}), $pc);
ok($pc->isBound);
