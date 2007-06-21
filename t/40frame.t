use Test::More tests => 4;

use IWL::Frame;

my $frame = IWL::Frame->new;

is($frame->getLabel, '');
is($frame->setLabel('My label'), $frame);
is($frame->getLabel, 'My label');
is($frame->getContent, "<fieldset><legend>My label</legend>\n</fieldset>\n");
