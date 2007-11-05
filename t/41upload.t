use Test::More tests => 4;

use IWL::Upload;


my $up = IWL::Upload->new;
is($up->setAccept('*.pl'), $up);
is($up->getAccept, '*.pl');
is($up->setLabel('Some label'), $up);
is($up->getLabel, 'Some label');
