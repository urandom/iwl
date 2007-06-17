#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Slider;

use strict;

use base 'IWL::Input';

use JSON;

use IWL::String qw(randomize);


=head1 NAME

IWL::Slider - a sliding control widget

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Input -> IWL::Slider

=head1 DESCRIPTION

The slider is a sliding control widget for setting values by dragging a handle

=head1 CONSTRUCTOR

IWL::Slider->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.
  disabled: true if the slider is disabled

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->{_tag} = 'div';
    $self->{_noChildren} = 0;
    $self->__init(%args);
    return $self;
}

=head1 METHODS

=over 4

=item B<setValue> (B<VALUE>)

Sets the value of the slider to B<VALUE>

Parameter: B<VALUE> - the data to be set as the value

=cut

sub setValue {
    my ($self, $value) = @_;

    $self->{_options}{sliderValue} = $value;
    return $self;
}

=item B<setDisabled> (B<BOOL>)

Sets whether the slider will be disabled

Parameters: B<BOOL> - true if the slider should be disabled (i.e. will not react to user input)

=cut

sub setDisabled {
    my ($self, $bool) = @_;

    if ($bool) {
	$self->{_options}{disabled} = 1;
    } else {
	$self->{_options}{disabled} = 0;
    }
    return $self;
}

=item B<setValues> (B<@VALUES>)

Sets the allowed values for the slider

Parameters: B<@VALUES> - an array of integers to be the only legal values for the slider

=cut

sub setValues {
    my ($self, @values) = @_;
    my @new_values;
    my $min;
    my $max;
    foreach my $value (@values) {
	next unless $value =~ /^[0-9]+$/;
	if (!$min) { $min = $value };
	if (!$max) { $max = $value };
	$max = $value > $max ? $value : $max;
	$min = $value < $min ? $value : $min;
	push @new_values, $value;
    }
    $self->{_options}{values} = \@new_values;
    $self->{__range} = "\$R($min, $max)" if !$self->{__range} && defined $min && defined $max;

    return $self;
}

=item B<setRange> (B<MIN>, B<MAX>)

Sets the allowed range for the slider

Parameters: B<MIN> - the minimum value of the slider, B<MAX> - the maximum value of the slider

=cut

sub setRange {
    my ($self, $min, $max) = @_;
    if ($min =~ /^[0-9.]+$/ && $max =~ /^[0-9.]+$/ && $min < $max) {
	$self->{__range} = "\$R($min, $max)";
    }

    return $self;
}

=item B<setVertical> (B<BOOL>)

Sets whether the slider is a vertical slider

Parameters: B<BOOL> - true of the slider should be vertical

=cut

sub setVertical {
    my ($self, $bool) = @_;

    if ($bool) {
	$self->{_options}{axis} = 'vertical';
    } else {
	$self->{_options}{axis} = 'horizontal';
    }

    return $self;
}

=item B<setSize> (B<SIZE>)

Sets the size of the slider

Parameters: B<SIZE> - the size of the slider in pixels, (width for a horizontal slider, height for a vertical one)

=cut

sub setSize {
    my ($self, $size) = @_;

    $size =~ s/\D//g;
    $self->{__size} = $size;

    return $self;
}

# Overrides
#

sub setId {
    my ($self, $id) = @_;

    $self->SUPER::setId($id);
    $self->{__rail}->setId($id . '_rail');
    return $self->{__handle}->setId($id . '_handle');
}

sub signalConnect {
    my ($self, $signal, $callback) = @_;
    if ($signal eq 'change') {
	push @{$self->{_customSignals}{change}}, $callback;
    } elsif ($signal eq 'slide') {
	push @{$self->{_customSignals}{slide}}, $callback;
    } else {
        $self->SUPER::signalConnect($signal, $callback);
    }

    return $self;
}

# Protected
#
sub _realize {
    my $self    = shift;
    my $script  = IWL::Script->new;
    my $id      = $self->getId;
    my $handle  = $self->{__handle}->getId;
    my $options = '';
    my $callbacks = '';
    my $onchange;
    my $onslide;
    my $range;

    if ($self->{_options}{axis} eq 'vertical') {
	$self->setStyle(height => $self->{__size} . 'px') if defined $self->{__size};
	$self->prependClass('vertical_slider');
    } else {
	$self->setStyle(width => $self->{__size} . 'px') if defined $self->{__size};
    }
    $self->SUPER::_realize;

    $onchange = join ';', @{$self->{_customSignals}{change}};
    $onslide = join ';', @{$self->{_customSignals}{slide}};
    $onchange = "onChange: function(value, control) { " . $onchange . " }" if $onchange;
    $onslide = "onSlide: function(value, control) { " . $onslide . " }" if $onslide;
    $range = "range: $self->{__range}" if $self->{__range};
    if ($onchange) {
	$callbacks = $onchange;
	$callbacks .= ', ' . $onslide if $onslide;
	$callbacks .= ', ' . $range if $range;
    } elsif ($onslide) {
	$callbacks = $onslide if $onslide;
	$callbacks .= ', ' . $range if $range;
    } else {
	$callbacks = $range if $range;
    }
    $options = objToJson($self->{_options});
    if ($options =~ /^{}$/) {
	$options = "{$callbacks}";
    } else {
	$options =~ s/^{/{$callbacks, /;
    }
    $script->setScript("\$('$id').control = new Control.Slider('$handle', '$id', $options)");
    $script->appendScript("\$('$id').signalConnect('mousewheel', function(event) {
	var control = \$('$id').control;
	if (control.options.values) {
	    var index = control.options.values.indexOf(control.value);
	    if (event.scrollDirection > 0) index++;
	    else index--;
	    if (index >= control.options.values.length) index--;
	    control.setValue(control.options.values[index]);
	} else {
	    var length = control.trackLength / control.increment;
	    var range = control.maximum - control.minimum;
	    control.setValueBy((range / length) * event.scrollDirection);
	}
	if(control.initialized && control.options.onSlide) 
	    control.options.onSlide(control.values.length>1 ? control.values : control.value, control);
    })");
    $self->_appendAfter($script);
}

sub _setupDefaultClass {
    my $self = shift;

    $self->prependClass($self->{_defaultClass});
    $self->{__rail}->prependClass($self->{_defaultClass} . '_rail');
    return $self->{__handle}->prependClass($self->{_defaultClass} . '_handle');
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $rail = IWL::Container->new;
    my $handle = IWL::Container->new;

    $self->{__rail}        = $rail;
    $self->{__handle}      = $handle;
    $self->{_defaultClass} = 'slider';

    $self->appendChild($rail, $handle);

    $args{id} = randomize($self->{_defaultClass}) if !$args{id};
    $self->{_options} = {};
    $self->{_options}{disabled} = 1 if $args{disabled};
    $self->{_options}{sliderValue} = 1 if $args{value};
    $self->{_options}{axis} = $args{vertical} ? 'vertical' : '';
    $self->{_customSignals} = {slide => [], change => []};
    delete @args{qw(disabled value)};
    $self->requiredJs('base.js', 'dist/slider.js');
    $self->_constructorArguments(%args);

    return $self;
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
