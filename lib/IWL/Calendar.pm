#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Calendar;

use strict;

use IWL::Script;
use IWL::String qw(randomize escape);
use IWL::Table::Row;
use IWL::Table::Cell;
use IWL::Input;

use base qw(IWL::Table);

use JSON;

=head1 NAME

IWL::Calendar - a calendar widget

=head1 INHERITANCE

L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Table> -> L<IWL::Calendar>

=head1 DESCRIPTION

The calendar widget provides a graphical calendar. It inherits from IWL::Table(3pm)

=head1 CONSTRUCTOR

IWL::Calendar->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values:

=over 4

=item B<fromYear>

Specifies the lower year boundary of the calendar. The year must include the century, e.g. I<2007>

=item B<fromMonth>

Specifies the lower month boundary of the calendar. Months range from 0 to 11

=item B<toYear>

Specifies the upper year boundary of the calendar. The year must include the century, e.g. I<2007>

=item B<toMonth>

Specifies the upper month boundary of the calendar. Months range from 0 to 11

=item B<startDate>

Sets the starting date of the calendar. Defaults to the current date. See IWL::Calendar::setDate(3pm)

=item B<showWeekNumbers>

True, if the week numbers should be shown. Defaults to I<true>. See IWL::Calendar::showWeekNumbers(3pm)

=item B<showHeading>

True, if the heading should be shown. Defaults to I<true>. See IWL::Calendar::showHeading(3pm)

=item B<showTime>

True, if the time should be shown. Defaults to I<true>. See IWL::Calendar::showTime(3pm)

=item B<showAdjacentMonths>

True, if days from the adjacent months should be shown. Defaults to I<true>

=item B<startOnMonday>

True, if the calendar week should start on monday. Defaults to I<true>

=item B<markWeekends>

True, if the weekends should differ visually from the week days. Defaults to I<true>

=item B<astronomicalTime>

True, if the displayed time should use astronomical notation (e.g. 15:00 instead of 3:00 pm). Defaults to I<true>

=item B<markedDates>

An array of dates that should be marked as special. See IWL::Calendar::markDate(3pm)

=back

=head1 SIGNALS

=over 4

=item B<change_month>

Fires when the month has been changed. Receives a I<Date> object as a parameter.

=item B<change_year>

Fires when the year has been changed. Receives a I<Date> object as a parameter.

=item B<change>

Fires when the date has been changed. Receives a I<Date> object and the current calendar date cell object as parameters.

=item B<load>

Fires when the calendar has been loaded.

=item B<select_date>

Fires when a date has been selected. Receives a I<Date> object and the current calendar date cell object as parameters.

=item B<activate_date>

Fires when a date has been activated, via double clicking. Receives a I<Date> object and the current calendar date cell object as parameters.

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new;

    $self->__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setDate> (B<DATE>)

Sets the starting date of the calendar.

Parameters: B<DATE> - the starting date, can be in the following formats:

=over 8

=item B<timestamp>

In seconds, or in milliseconds

=item B<year>, B<month>, B<date>, [B<hours>, B<minutes>, B<seconds>, B<milliseconds>]

=back

=cut

sub setDate {
    my ($self, @date) = @_;

    return if !@date;
    my $date_length = @date;

    if ($date_length == 1) {
        my $timestamp = $date[0];
        return unless $timestamp;

        $timestamp *= 1000 if length $timestamp == 10;

        return if length $timestamp != 13;

        $self->{_options}{startDate} = $timestamp;
    } else {
        return if $date_length < 3;
        $self->{_options}{startDate} = [@date];
    }
    return $self;
}

=item B<getDate>

Returns the starting date of the calendar

=cut

sub getDate {
    my $self = shift;
    
    return (ref $self->{_options}{startDate} eq 'ARRAY')
      ? @{$self->{_options}{startDate}} : $self->{_options}{startDate};
}

=item B<showWeekNumbers> (B<BOOL>)

Sets whether the week numbers should be shown.

Parameters: B<BOOL> - true if the week numbers should be shown

=cut

sub showWeekNumbers {
    my ($self, $bool) = @_;

    $self->{_options}{showWeekNumbers} = !(!$bool);

    return $self;
}

=item B<showHeading> (B<BOOL>)

Sets whether the heading should be shown.

Parameters: B<BOOL> - true if the heading should be shown

=cut

sub showHeading {
    my ($self, $bool) = @_;

    $self->{_options}{showHeading} = !(!$bool);

    return $self;
}

=item B<showTime> (B<BOOL>)

Sets whether the time should be shown.

Parameters: B<BOOL> - true if the time should be shown

=cut

sub showTime {
    my ($self, $bool) = @_;

    $self->{_options}{showTime} = !(!$bool);

    return $self;
}

=item B<markDate> (B<DATE>)

Sets the given date as a marked date.

Parameters: B<DATE> - a date to mark. Can be an array of dates. The date should have the following format:

  {year => 2007, month => 5, date => 11}

where I<year> and I<month> are optional.

=cut

sub markDate {
    my ($self, @dates) = @_;

    foreach my $date (@dates) {
        next unless defined $date->{date};
        next if $date->{year} && !defined $date->{month};

        push @{$self->{_options}{markedDates}}, $date;
    }

    return $self;
}

=item B<unmarkDate> (B<DATE>)

Removes the given date from the list of marked dates.

Parameters: B<DATE> - a date to unmark. See IWL::Calendar::markDate(3pm) for more information.

=cut

sub unmarkDate {
    my ($self, @dates) = @_;

    foreach my $date (@dates) {
        my $day = $date->{date};
        my $month = $date->{month};
        my $year = $date->{year};

        next unless $day;
        $self->{_options}{markedDates} = [
          grep {
              ($_->{date} == $day &&
               ((!defined  $_->{month} && !defined $month)
                || $_->{month} == $month
               ) &&
               ((!defined  $_->{year} && !defined $year)
                || $_->{year} == $year
               )
              )
          } @{$self->{_options}{markedDates}}
        ];
    }

    return $self;
}

=item B<clearMarks>

Clears all marked dates.

=cut

sub clearMarks {
    my $self = shift;

    $self->{_options}{markedDates} = [];
    return $self;
}

=item B<updateOnSignal> (B<SIGNAL>, B<ELEMENT>, B<FORMAT>)

Updates the given B<ELEMENT> with data, formatted using B<FORMAT> when B<SIGNAL> has been emitted.

Parameters: B<SIGNAL> - the signal to which to connect. B<ELEMENT> - the element to update, it must have a valid I<id>. B<FORMAT> - the format, which will be used to format the date. See strftime(3)

=cut

sub updateOnSignal {
    my ($self, $signal, $element, $format) = @_;

    my $id = UNIVERSAL::isa($element, 'IWL::Widget') ? $element->getId : $element;
    push @{$self->{__updates}}, [$signal, $id, $format];
    return $self;
}

# Overrides
#
sub setId {
    my ($self, $id) = @_;

    $self->SUPER::setId($id);

    return $self;
}

# Protected
#
sub _realize {
    my $self    = shift;
    my $script  = IWL::Script->new;
    my $id      = $self->getId;

    $self->SUPER::_realize;
    my $options = objToJson($self->{_options});

    $script->setScript("Calendar.create('$id', $options);");
    foreach my $update (@{$self->{__updates}}) {
        $script->appendScript(qq|\$('$id').updateOnSignal('$update->[0]', '$update->[1]', '$update->[2]')|);
    }
    $self->_appendAfter($script);
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $default_class = 'calendar';
    my $id = $args{id} || randomize($default_class);
    my $options = {};

    $options->{fromYear}  = $args{fromYear}  if defined $args{fromYear};
    $options->{fromMonth} = $args{fromMonth} if defined $args{fromMonth};
    $options->{toYear}    = $args{fromYear}  if defined $args{toYear};
    $options->{toMonth}   = $args{toMonth}   if defined $args{toMonth};

    $options->{showWeekNumbers}    = !(!$args{showWeekNumbers})    if defined $args{showWeekNumbers};
    $options->{showHeading}        = !(!$args{showHeading})        if defined $args{showHeading};
    $options->{showTime}           = !(!$args{showTime})           if defined $args{showTime};
    $options->{showAdjacentMonths} = !(!$args{showAdjacentMonths}) if defined $args{showAdjacentMonths};
    $options->{startOnMonday}      = !(!$args{startOnMonday})      if defined $args{startOnMonday};
    $options->{markWeekends}       = !(!$args{markWeekends})       if defined $args{markWeekends};
    $options->{astronomicalTime}   = !(!$args{astronomicalTime})   if defined $args{astronomicalTime};

    $options->{markedDates} = [];

    $self->{_options}  = $options;
    $self->{__updates} = [];

    $self->setDate($args{startDate});
    $self->markDate(@{$args{markedDates}});
    delete @args{qw(fromYear fromMonth toYear toMonth showWeekNumbers
                    showHeading showTime showAdjacentMonths startOnMonday
                    markWeekends astronomicalTime startDate markedDates id)};

    $self->{_defaultClass} = $default_class;
    $self->setId($id);
    $self->requiredJs('base.js', 'calendar.js');

    $self->_constructorArguments(%args);
    $self->{_customSignals} = {
         change_month  => [],
         change_year   => [],
         change        => [],
         load          => [],
         select_date   => [],
         activate_date => []
    };

    my $heading = IWL::Table::Row->new(class => 'calendar_heading');
    $heading->appendCell(undef, class => 'calendar_week_number_header');
    my $month_cell = $heading->appendCell(undef, class => 'calendar_month_cell', colspan => 4);
    $month_cell->appendChild(
        IWL::Container->new(
            inline => 1, class => 'calendar_month_prev'
        )->appendChild(IWL::Text->new('&lt;')),
        IWL::Input->new(type => 'text', class => 'calendar_month'),
        IWL::Container->new(
            inline => 1, class => 'calendar_month_next'
        )->appendChild(IWL::Text->new('&gt;')),
    );
    my $year_cell = $heading->appendCell(undef, class => 'calendar_year_cell', colspan => 2);
    $year_cell->appendChild(
        IWL::Container->new(
            inline => 1, class => 'calendar_year_prev'
        )->appendChild(IWL::Text->new('&lt;')),
        IWL::Input->new(type => 'text', class => 'calendar_year'),
        IWL::Container->new(
            inline => 1, class => 'calendar_year_next'
        )->appendChild(IWL::Text->new('&gt;')),
    );
    $heading->appendCell(undef, class => 'calendar_week_day_header');

    my $week_days = IWL::Table::Row->new(class => 'calendar_week_days');
    $week_days->appendCell(undef, class => 'calendar_week_number_header');
    $week_days->appendChild(IWL::Table::Cell->newMultiple(7, class => 'calendar_week_day_header'));

    $self->appendHeader($heading);
    $self->appendHeader($week_days);

    my @week_rows = IWL::Table::Row->newMultiple(6, class => 'calendar_week');
    foreach my $row (@week_rows) {
        $row->appendCell(undef, class => 'calendar_week_number');
        $row->appendChild(IWL::Table::Cell->newMultiple(7, class => 'calendar_week_day'));
        $self->appendBody($row);
    }
    my $time_row = IWL::Table::Row->new(class => 'calendar_time');
    $time_row->appendCell(undef, colspan => 3);
    my $time_cell = $time_row->appendCell(undef, colspan => 3);
    $time_cell->appendChild(
        IWL::Input->new(type => 'text', class => 'calendar_hours'),
        IWL::Text->new(':'),
        IWL::Input->new(type => 'text', class => 'calendar_minutes'),
        IWL::Text->new(':'),
        IWL::Input->new(type => 'text', class => 'calendar_seconds'),
        IWL::Container->new(inline => 1, class => 'calendar_hours_notation')
    );
    $time_row->appendCell(undef, colspan => 2);

    $self->appendBody($time_row);
}

1;

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2007  Viktor Kojouharov. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut