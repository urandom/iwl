#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Calendar;

use strict;

use base qw (IWL::Widget);

use IWL::Config qw(%IWLConfig);
use IWL::Script;
use IWL::Style;

use Locale::TextDomain qw (org.imperia.iwl);

# Ouch ... this has to be package global.
my $style;

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $button = $args{button};
    delete $args{button};

    my $self = $class->SUPER::new (%args);

    my $id = $args{id};
    unless ($id && $id =~ /^[A-Za-z_][0-9A-Za-z_]*$/) {
	$id = "$self";
	$id =~ s/.*0x([0-9a-fA_F]+)\)$/iwl_cal_$1/;
    }

    # Set defaults.
    $self->{__iwlCalendarDisplayWeekNumbers} = 1;
    $self->{__iwlCalendarInputFields} = [];
    $self->{__iwlCalendarDisplayContainers} = [];
    $self->{__iwlCalendarPopupMode} = 0;
    $self->{__iwlCalendarSeqNumber} = 0;
    $self->{__iwlCalendarBoolWeekNumbers} = 0;
    $self->{__iwlCalendarBoolShowOthers} = 0;
    $self->{__iwlCalendarBoolShowsTime} = 0;
    $self->{__iwlCalendarIntFirstDayOfWeek} = 1;
    $self->{__iwlCalendarStringStartDate} = 1000 * time;
    $self->{__iwlCalendarStartYear} = 1900;
    $self->{__iwlCalendarEndYear} = 2999;

    if ($args{button}) {
	my $id = $button->getId;
	unless ($id) {
	    require Carp;
	    Carp::carp ("Trigger button has no id attribute");
	} else {
	    $self->{__iwlCalendarButton} = $id;
	}
    }

    $self->setId ($id);

    my $script = $self->{__iwlCalendarScript} = IWL::Script->new;

    # $self->appendChild ($script);

    # FIXME: Is that okay?
    # $self->{_noChildren} = 1;

    # Ouch!
    $self->{_tag} = 'span';

    return $self;
}

# Class method!
sub getRequiredScripts {
    my $class = shift;

    my $link1 = IWL::Script->new;
    $link1->setSrc ($IWLConfig{JS_DIR} . '/dist/calendar.js');

    my $link2 = IWL::Script->new;
    $link2->setSrc ($IWLConfig{JS_DIR} . '/calendar-create.js');


    return [$link1, $link2];
}


sub __getLangScript {
    my $class = shift;

    my $source = "\nCalendar._DN = new Array (";
    $source .= '"' . $class->__escape_one_line_js (__"Sunday") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"Monday") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"Tuesday") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"Wednesday") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"Thursday") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"Friday") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"Saturday") . '");';

    my $snippet = "\nCalendar._SDN = new Array (";
    # TRANSLATORS: Abbreviated week day name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SDN}Sun") . '", ';
    # TRANSLATORS: Abbreviated week day name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SDN}Mon") . '", ';
    # TRANSLATORS: Abbreviated week day name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SDN}Tue") . '", ';
    # TRANSLATORS: Abbreviated week day name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SDN}Wed") . '", ';
    # TRANSLATORS: Abbreviated week day name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SDN}Thu") . '", ';
    # TRANSLATORS: Abbreviated week day name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SDN}Fri") . '", ';
    # TRANSLATORS: Abbreviated week day name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SDN}Sat") . '");';
    $snippet =~ s/\{SDN\}//g;
    $source .= $snippet;

    # TRANSLATORS: Only replace the digit (0 = Sunday, 6 = Saturday)!
    my $first_day_of_week = __x ("{first_day_of_week}0",
				 first_day_of_week => 0);
    $first_day_of_week = 0 unless $first_day_of_week =~ /^\s*([0-6])\s*$/;
    $source .= "\nCalendar._FD = $first_day_of_week;\n";

    $source .= "Calendar._MN = new Array (";
    $source .= '"' . $class->__escape_one_line_js (__"January") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"February") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"March") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"April") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"May") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"June") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"July") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"August") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"September") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"October") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"November") . '", ';
    $source .= '"' . $class->__escape_one_line_js (__"December") . '");';

    $snippet .= "\nCalendar._SMN = new Array (";
    # TRANSLATORS: Abbreviated month name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SMN}Jan") . '", ';
    # TRANSLATORS: Abbreviated month name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SMN}Feb") . '", ';
    # TRANSLATORS: Abbreviated month name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SMN}Mar") . '", ';
    # TRANSLATORS: Abbreviated month name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SMN}Apr") . '", ';
    # TRANSLATORS: Abbreviated month name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SMN}May") . '", ';
    # TRANSLATORS: Abbreviated month name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SMN}Jun") . '", ';
    # TRANSLATORS: Abbreviated month name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SMN}Jul") . '", ';
    # TRANSLATORS: Abbreviated month name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SMN}Aug") . '", ';
    # TRANSLATORS: Abbreviated month name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SMN}Sep") . '", ';
    # TRANSLATORS: Abbreviated month name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SMN}Oct") . '", ';
    # TRANSLATORS: Abbreviated month name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SMN}Nov") . '", ';
    # TRANSLATORS: Abbreviated month name!
    $snippet .= '"' . $class->__escape_one_line_js (__"{SMN}Dec") . '");';
    $snippet =~ s/\{SMN\}//g;
    $source .= $snippet;

    $source .= "\nCalendar._TT = {};\n";
    $source .= qq{Calendar._TT["ABOUT"] =\n};
    $source .= qq{"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\\n" +\n};

    $snippet = '"' . $class->__escape_one_line_js (__x (<<EOF));
For latest version visit: http://www.dynarch.com/projects/calendar/
Distributed under GNU LGPL.  See http://gnu.org/licenses/lgpl.html for details.

Date selection:
- Use the {left_dbl_arrow} and {right_dbl_arrow} buttons to select year
- Use the {left_arrow} and {right_arrow} buttons to select month
- Hold mouse button on any of the above buttons for faster selection.
EOF
    $snippet .= "\";\n";
    $snippet =~ s/{left_dbl_arrow}/\\u00ab/g;
    $snippet =~ s/{right_dbl_arrow}/\\u00bb/g;
    $snippet =~ s/{left_arrow}/\\u2039/g;
    $snippet =~ s/{right_arrow}/\\u203a/g;
    $source .= $snippet;

    $source .= qq{Calendar._TT["ABOUT_TIME"] =\n};
    $source .= '"' . $class->__escape_one_line_js (__(<<EOF)) . "\";\n";
Time selection:
- Click on any of the time parts to increase it
- or Shift-click to decrease it
- or click and drag for faster selection.
EOF

    $source .= qq{Calendar._TT["PREV_MONTH"] = \"}
    . $class->__escape_one_line_js (__"Month back")
	. "\"\n";
    $source .= qq{Calendar._TT["PREV_YEAR"] = \"}
    . $class->__escape_one_line_js (__"Year back")
	. "\"\n";
    $source .= qq{Calendar._TT["GO_TODAY"] = \"}
    . $class->__escape_one_line_js (__"Go to today") . "\"\n";
    $source .= qq{Calendar._TT["NEXT_MONTH"] = \"}
    . $class->__escape_one_line_js (__"Month forward") . "\"\n";
    $source .= qq{Calendar._TT["NEXT_YEAR"] = \"}
    . $class->__escape_one_line_js (__"Year forward") . "\"\n";
    $source .= qq{Calendar._TT["SEL_DATE"] = \"}
    . $class->__escape_one_line_js (__"Select date") . "\"\n";
    $source .= qq{Calendar._TT["DRAG_TO_MOVE"] = \"}
    . $class->__escape_one_line_js (__"Drag to move") . "\"\n";
    $source .= qq{Calendar._TT["PART_TODAY"] = \"}
    . $class->__escape_one_line_js (__"(today)") . "\"\n";

    $source .= qq{Calendar._TT["DAY_FIRST"] = \"}
    . $class->__escape_one_line_js (__"Display %s first") . "\"\n";

    # TRANSLATORS: Replace the digits with a comma separated list
    # TRANSLATORS: week days that are considered weekend days in
    # TRANSLATORS: your locale (Sunday - 0, Saturday - 6).
    my $weekend = __x ("{weekend}0,6", weekend => '');
    $weekend = '0,6' unless $weekend =~ /^(?:[0-6],)*[0-6]$/;
    $source .= qq{Calendar._TT["WEEKEND"] = "$weekend";\n};

    $source .= qq{Calendar._TT["CLOSE"] = \"}
    . $class->__escape_one_line_js (__"Close") . "\"\n";
    $source .= qq{Calendar._TT["TODAY"] = \"}
    . $class->__escape_one_line_js (__"Today") . "\"\n";
    $source .= qq{Calendar._TT["TIME_PART"] = \"}
    . $class->__escape_one_line_js (__"(Shift-)click or drag to change value")
	. "\"\n";

    $source .= qq{Calendar._TT["WK"] = \"}
    # TRANSLATORS: Short(!) abbreviation for week number.
    . $class->__escape_one_line_js (__"wk") . "\"\n";
    $source .= qq{Calendar._TT["TIME"] = \"}
    . $class->__escape_one_line_js (__"Time:") . "\"\n";

    $source .= qq{Calendar._TT["DEF_DATE_FORMAT"] = \"}
    # TRANSLATORS: See the docs at
    # TRANSLATORS: http://www.dynarch.com/demos/jscalendar/doc/html/reference.html#node_sec_5.3.5
    # TRANSLATORS: for a list of possible options.
    # no-perl-format
    . $class->__escape_one_line_js (__"%Y-%m-%d") . "\"\n";

    $source .= qq{Calendar._TT["TT_DATE_FORMAT"] = \"}
    # TRANSLATORS: Default format for date without year.  See the docs at
    # TRANSLATORS: http://www.dynarch.com/demos/jscalendar/doc/html/reference.html#node_sec_5.3.5
    # TRANSLATORS: for a list of possible options.
    # no-perl-format
    . $class->__escape_one_line_js (__"%a, %b %e") . "\"\n";

    my $lang_js = IWL::Script->new;
    $lang_js->setScript($source);

    return $lang_js;
}

# Class method!
sub getRequiredStyles {
    my ($class) = @_;

    return [$style] if $style;

    my $default_path = $IWLConfig{SKIN_DIR} . '/calendar/default/theme.css';
    my $default_style = IWL::Page::Link->newLinkToCSS($default_path);

    return [$default_style];
}

sub setId {
    my ($self, $id) = @_;

    return $self->_pushFatalError ("invalid id '$id'")
	unless ($id && $id =~ /^[A-Za-z_][0-9A-Za-z_]*/);

    return $self->SUPER::setId ($id);
}

sub setPopupMode {
    my ($self, $flag) = @_;

    $self->{__iwlCalendarPopupMode} = $flag;

    return $self;
}

sub showWeekNumbers {
    my ($self, $flag) = @_;

    $self->{__iwlCalendarBoolWeekNumbers} = $flag;

    return $self;
}

sub showAdjacentMonths {
    my ($self, $flag) = @_;

    $self->{__iwlCalendarBoolShowOthers} = $flag;

    return $self;
}

sub showTime {
    my ($self, $flag) = @_;

    $self->{__iwlCalendarBoolShowsTime} = $flag;

    return $self;
}

sub setFirstDayOfWeek {
    my ($self, $daynum) = @_;

    return $self->_pushError (__"invalid day number (must be 0-6)")
	unless defined $daynum && $daynum =~ /^[0-6]$/;
    $self->{__iwlCalendarIntFirstDayOfWeek} = $daynum;

    return $self;
}

sub startDate {
    my ($self, $start_date) = @_;

    $self->{__iwlCalendarStringStartDate} = 1000 * $start_date;

    return $self;
}

sub seqNumber {
   my ($self, $number) = @_;

   $self->{__iwlCalendarSeqNumber} = $number
       if defined $number;

   return $self->{__iwlCalendarSeqNumber};
}

sub startYear {
   my ($self, $year) = @_;

   $year =~ s/[^0-9]//;
   $year = $self->__escape_one_line_js ($year);
   $self->{__iwlCalendarStartYear} = $year
       if $year =~ /^[0-9]{1,4}$/;

   return $self;
}

sub endYear {
   my ($self, $year) = @_;

   $year =~ s/[^0-9]//;
   $year = $self->__escape_one_line_js ($year);
   $self->{__iwlCalendarEndYear} = $year
       if $year =~ /^[0-9]{1,4}$/;

   return $self;
}

# Class method!
sub setSkin {
    my ($proto, $skin) = @_;

    if (ref $skin && $skin->isa ('IWL::Style')) {
	$style = $skin;
    } else {
	$style =  IWL::Page::Link->newLinkToCSS($skin);
    }

    return $proto;
}

sub connectInputField {
    my ($self, $input, $format) = @_;

    my $input_id = $input->getId;
    return $self->_pushError ("input field has no id")
	unless defined $input_id && length $input_id;

    $format = "%s" unless defined $format && length $format;

    push @{$self->{__iwlCalendarInputFields}}, {
	id => $input_id,
	format => $format,
    };

    return $self;
}

sub connectInputId {
    my ($self, $input_id, $format) = @_;

    $format = "%s" unless defined $format && length $format;

    push @{$self->{__iwlCalendarInputFields}}, {
	id => $input_id,
	format => $format,
    };

    return $self;
}

sub connectDisplayContainer {
    my ($self, $container, $format) = @_;

    my $container_id = $container->getId;
    return $self->_pushError (__"container has no id")
	unless defined $container_id && length $container_id;

    $format = "%s" unless defined $format && length $format;

    push @{$self->{__iwlCalendarDisplayContainers}}, {
	id => $container_id,
	format => $format,
    };

    return $self;
}

sub connectDisplayId {
    my ($self, $container_id, $format) = @_;

    $format = "%s" unless defined $format && length $format;

    push @{$self->{__iwlCalendarDisplayContainers}}, {
	id => $container_id,
	format => $format,
    };

    return $self;
}

sub getContent {
    my ($self) = @_;

    $self->__updateContent or return;

    $self->SUPER::getContent;
}

sub getObject {
    my ($self) = @_;

    $self->__updateContent or return;

    $self->SUPER::getObject;
}

sub __updateContent {
    my ($self) = @_;

    my $id = $self->getId;

    my $script_source = <<EOF;
  window.__iwl_cal_param_$id = {
EOF

    unless ($self->{__iwlCalendarPopupMode}) {
	# Flat calendar.
	my $parent = $self->{parentNode};
	unless (defined $parent) {
	    return $self->_pushError ("calendar has no parent object");
	}

	my $parent_id = $parent->getId;
	unless (defined $parent_id && length $parent_id) {
	    # It is too late now for inventing a parent id, because
	    # the opening tag of our parent is already written.
	    warn "calendar\'s parent object has no id";
	    return $self->_pushError ("calendar\'s parent object has no id");
	} else {
	    $parent_id =~ s/\\/\\\\/g;
	    $parent_id =~ s/\"/\\\"/g;
	}
	$script_source .= qq{flat: "$parent_id",\n};
    } else {
	$script_source .= qq{button: "$self->{__iwlCalendarTriggerId}",\n};
        $script_source .= qq{cache: 1, \n};
        $script_source .= qq{seq_number: $self->{__iwlCalendarSeqNumber}, \n};
    }

    foreach my $property (qw (weekNumbers showOthers showsTime)) {
	my $value = $self->{"__iwl_calendar_bool_$property"} ?
	    'true' : 'false';
	$script_source .= "$property: $value,\n";
    }

    $script_source .= "date: new Date(),\n";

    $script_source .=
	"firstDay: $self->{__iwlCalendarIntFirstDayOfWeek},\n";

    if (@{$self->{__iwlCalendarInputFields}}) {
	$script_source .= "inputFields: [\n";
	foreach my $entry (@{$self->{__iwlCalendarInputFields}}) {
	    my $input_id = $entry->{id};
	    my $format = $self->__escape_one_line_js ($entry->{format});
	    $script_source .= qq<{id: "$input_id", format: "$format"},\n>;
	}
	$script_source .= "],\n";
    }
    if (@{$self->{__iwlCalendarDisplayContainers}}) {
	$script_source .= "displayAreas: [\n";
	foreach my $entry (@{$self->{__iwlCalendarDisplayContainers}}) {
	    my $input_id = $entry->{id};
	    my $format = $self->__escape_one_line_js ($entry->{format});
	    $script_source .= qq<{id: "$input_id", format: "$format"},\n>;
	}
	$script_source .= "],\n";
    }

    $script_source .= <<EOF;
range: [$self->{__iwlCalendarStartYear}, $self->{__iwlCalendarEndYear}],
EOF

    # The empty array is important so that no trailing comma is in the
    # hash.
    $script_source .= "dummy:[]\n};\n";
    $script_source .= <<EOF;
window.__iwl_cal_param_$id.date.setTime ($self->{__iwlCalendarStringStartDate});
Calendar.create (__iwl_cal_param_$id);
EOF

    if ($self->{__iwlCalendarTriggerId} &&
	!$self->{__iwlCalendarTrigger}) {
	my $callback = $self->getTriggerCallback;
	my $trigger_id = $self->{__iwlCalendarTriggerId};
	my $signal = $self->{__iwlCalendarTrggerSignal} || 'click';

	$script_source .= <<EOF;
var cal_trigger_$id = document.getElementById ("$trigger_id");
if (cal_trigger_$id) {
    cal_trigger_$id\["on$signal"] = function () {
        $callback;
	__iwl_cal_param_${id}\["button"] = "$trigger_id";
        return false;
    }
}
EOF
    }

    $self->{__iwlCalendarScript}->setScript ($script_source);
    $self->_appendAfter(
        $self->__getLangScript,
        $self->{__iwlCalendarScript},
    );

    return $self;
}

sub getTriggerCallback {
    my $id = shift->getId;

    return "iwl_calendar_popup (__iwl_cal_param_$id)";
}

sub connectToTrigger {
    my ($self, $trigger, $signal) = @_;

    my $trigger_id = $trigger->getId;
    unless (defined $trigger_id && length $trigger_id) {
	return $self->_pushError ("connected trigger has no id");
    }

    $self->{__iwlCalendarTriggerId} = $trigger_id;
    $self->{__iwlCalendarTrigger} = $trigger;
    $signal = 'click' unless defined $signal && length $signal;
    my $id = shift->getId;
    my $callback = "iwl_calendar_popup (__iwl_cal_param_$id)";
    $trigger->signalConnect($signal, $callback);

    return $self;
}

sub connectToTriggerId {
    my ($self, $trigger_id, $signal) = @_;

    $self->{__iwlCalendarTriggerId} = $trigger_id;
    $self->{__iwlCalendarTriggerSignal} = $signal;

    return $self;
}

# This must also be a class method because it is called from a class method!
sub __escape_one_line_js {
    my ($class, $string) = @_;

    return unless defined $string;

    $string = $class->__escape_js ($string);
    $string =~ s/\n/\\n/g;

    return $string;
}

# This must also be a class method because it is called from a class method!
sub __escape_js {
    my (undef, $string) = @_;

    return unless defined $string;

    $string =~ s/\\/\\\\/g;
    $string =~ s/&/\\&/g;
    $string =~ s/</\\</g;
    $string =~ s/>/\\>/g;
    $string =~ s/\"/\\\"/g; #" St. Emacs
    $string =~ s/\'/\\\'/g; #'

    return $string;
}

1;

=head1 NAME

IWL::Calendar - A calendar object.

=head1 SYNOPSIS

    use IWL::Calendar;

    my $cal = IWL::Calendar->new;

=head1 DESCRIPTION

The B<IWL::Calendar> object provides a customizable calendar widget.
The module is based on the DHTML calendar available at
L<http://www.dynarch.com/projects/calendar>.

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Calendar

=head1 CONSTRUCTORS

=over 4

=item B<new>

The constructor takes no arguments and cannot fail.

=back

=head1 PUBLIC METHODS

=over 4

=item B<setDisplayType (TYPE)>

Sets the display type of the calendar to either "popup" or
"flat" (the default).  The method will fail and return false
if you pass an invalid display type.

=back

=head1 CLASS METHODS

=over 4

=back

=head1 SEE ALSO

IWL::Widget(3pm), perl(1)

=cut

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
