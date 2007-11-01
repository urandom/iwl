use Test::More tests => 4;

use IWL::PageControl;

my $pc = IWL::PageControl->new;
my $con = IWL::Container->new;
is($pc->bindToWidget($con, 'iwl_demo.pl', {foo => 'bar'}), undef);
ok(!$pc->isBound);
$con->setId('bar');
is($pc->bindToWidget($con, 'iwl_demo.pl', {foo => 'bar'}), $pc);
ok($pc->isBound);
