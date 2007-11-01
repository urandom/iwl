use Test::More tests => 5;

use IWL::Upload;


my $up = IWL::Upload->new;
is($up->setAccept('*.pl'), $up);
is($up->getAccept, '*.pl');
is($up->setLabel('Some label'), $up);
is($up->getLabel, 'Some label');
is($up->setUploadCallback('alert'), $up);
