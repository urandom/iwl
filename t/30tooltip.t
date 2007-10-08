use Test::More tests => 7;

use IWL::Tooltip;

my $t = IWL::Tooltip->new(id => 'tooltip');
is($t->bindToWidget(IWL::Widget->new, 'click'), undef);
is($t->bindToWidget(IWL::Widget->new(id => 'foo'), 'click'), $t);
is($t->bindHideToWidget(IWL::Widget->new, 'mouseout'), undef);
is($t->bindHideToWidget(IWL::Widget->new(id => 'foo'), 'mouseout'), $t);
is($t->setContent(IWL::Widget->new), $t);

is($t->showingCallback, q|$('tooltip').showTooltip()|);
is($t->hidingCallback, q|$('tooltip').hideTooltip()|);
