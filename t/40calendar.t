use Test::More tests => 15;

use IWL::Calendar;

{
    my $c = IWL::Calendar->new;
    is($c->setDate(time * 1000), $c);
    is($c->setDate(time), $c);
    is($c->setDate(2007, 11, 5), $c);
    is($c->setDate(2007, 23, 12, 5, 12, 31), $c);
    is_deeply([$c->getDate], [2007, 23, 12, 5, 12, 31]);
    is($c->showWeekNumbers(1), $c);
    is($c->showHeading(1), $c);
    is($c->showTime(1), $c);
    is($c->markDate({year => 2007, month => 8, date => 15}), $c);
    is($c->markDate({month => 9, date => 5}), $c);
    is($c->markDate({date => 21}), $c);
    is($c->unmarkDate({month => 9, date => 5}), $c);
    is($c->clearMarks, $c);
}

{
    my $c = IWL::Calendar->new;
    my $t = IWL::Table->new;

    is($c->updateOnSignal(change => 'some_id', '%T'), $c);
    is($c->updateOnSignal(activate_date => $t, '%F'), $c);
}
