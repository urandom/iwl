#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Spinner;

use strict;

use base 'IWL::Entry';

use IWL::String qw(randomize);
use IWL::JSON qw(toJSON);

=head1 NAME

IWL::Spinner - a number spinner widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Input> -> L<IWL::Entry> -> L<IWL::Spinner>

=head1 DESCRIPTION

The entry widget is a single-line, text entry, also capable of showing password-type fields.

=head1 CONSTRUCTOR

IWL::Entry->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<readonly>

Set to true if the spinner input is read-only

=item B<maxlength>

The maximum number of characters the spinner can hold

=item B<size>

The size of the spinner input

=item B<value>

The starting value of the spinner. Defaults to I<0>

=item B<from>

The lower range of the spinner. Defaults to I<0>

=item B<to>

The upper range of the spinner. Defaults to I<100>

=item B<stepIncrement>

The step increment of the spinner. Defaults to I<1.0>

=item B<pageIncrement>

The page increment of the spinner. Defaults to I<10.0>

=item B<acceleration>

The acceleration of the spinner. Defaults to I<0.1>

=item B<snap>

True, if the spinner should snap. Defaults to I<false>

=item B<wrap>

True, if the spinner should wrap. Defaults to I<false>

=item B<precision>

The numeric precision of the spinner, in fixed-point notation

=item B<mask>

The spinner mask

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setRange> (B<FROM>, B<TO>)

Sets the range of the spinner

Parameter: B<FROM> - the lower numeric value, B<TO> - the upper numeric value

=cut

sub setRange {
    my ($self, $from, $to) = @_;

    $self->{_options}{from} = $from;
    $self->{_options}{to} = $to;

    return $self;
}

=item B<getRange>

Returns an array with the lower and upper numeric limits of the spinner

=cut

sub getRange {
    my $self = shift;

    return $self->{_options}{from}, $self->{_options}{to};
}

=item B<setPrecision> (B<PRECISION>)

Sets the precision of the spinner, in fixed-point notation

Parameters: B<PRECISION> - the precision number, between I<0> and I<20>

=cut

sub setPrecision {
    my ($self, $precision) = @_;

    $self->{_options}{precision} = $precision;
    return $self;
}

=item  B<getPrecision>

Returns the precision of the spinner

=cut

sub getPrecision {
    return shift->{_options}{precision};
}

=item B<setIncrements> (B<STEP>, B<PAGE>)

Sets the step and page increments of the spinner

Parameters: B<STEP> - a float number, corresponding to the step increment, B<PAGE> - a float number, corresponding to the page increment (shift-click, shift-arrow)

=cut

sub setIncrements {
    my ($self, $step, $page) = @_;

    $self->{_options}{stepIncrement} = $step;
    $self->{_options}{pageIncrement} = $page;

    return $self;
}

=item B<getIncrements>

Returns an array of the step and page increments

=cut

sub getIncrements {
    my $self = shift;

    return $self->{_options}{stepIncrement}, $self->{_options}{pageIncrement};
}

=item B<setAcceleration> (B<ACCELERATION>)

Sets the acceleration of the spinner incrementation

Parameters: B<ACCELERATION> - a float number, corresponding to the acceleration of the spinner

=cut

sub setAcceleration {
    my ($self, $acceleration) = @_;

    $self->{_options}{acceleration} = $acceleration;
    return $self;
}

=item B<getAcceleration>

Returns the spinner acceleration

=cut

sub getAcceleration {
    return shift->{_options}{acceleration};
}

=item B<setValue> (B<VALUE>)

Sets the initial value of the spinner

Parameters: B<VALUE> - the numerical value of the spinner

=cut

sub setValue {
    my ($self, $value) = @_;

    $self->{_options}{value} = $value;
    return $self;
}

=item B<getValue>

Returns the initial value of the spinner

=cut

sub getValue {
    return shift->{_options}{value};
}

=item B<setWrap> (B<BOOL>)

Sets whether the spinner will wrap if it gets an out-of-range value

Parameters: B<BOOL> - true, if the spinner should wrap

=cut

sub setWrap {
    my ($self, $bool) = @_;

    $self->{_options}{wrap} = $bool ? 1 : 0;
    return $self;
}

=item B<isWrapping>

Returns true if the spinner wraps

=cut

sub isWrapping {
    return shift->{_options}{wrap} eq 1 ? 1 : '';
}

=item B<setSnap> (B<BOOL>)

Sets whether the spinner will try to adjust incorrect values to the nearest possible one

Parameters: B<BOOL> - true, if the spinner should snap

=cut

sub setSnap {
    my ($self, $bool) = @_;

    $self->{_options}{snap} = $bool? 1 : 0;
    return $self;
}

=item B<isSnapping>

Returns true if the spinner snaps

=cut

sub isSnapping {
    return shift->{_options}{snap} eq 1 ? 1 : '';
}

=item B<setMask> (B<MASK>)

Sets the mask of the spinner. A mask defines a string, a portion of which represents the numeric value, and the rest is text.

Parameters: B<MASK> - a string mask. In order to display the spinner value, the string must contain I<#{number}>. e.g.: "#{number} euro"

=cut

sub setMask {
    my ($self, $mask) = @_;

    $self->{_options}{mask} = $mask;
    return $self;
}

=item B<getMask>

Returns the mask of the spinner

=cut

sub getMask {
    return shift->{_options}{mask};
}

# Overrides
#

=item B<setId> (B<ID>, [B<CONTROL_ID>])

Sets the id of the entry and all of it's parts. Can optionally set the id of the control.

Parameters: B<ID> - the id of the entry, B<CONTROL_ID> - the id of the text control, optional

=cut

sub setId {
    my ($self, $id, $control_id) = @_;

    $self->setAttribute(id => $id);
    $self->{image1}->setId($id . '_left');
    $self->{image2}->setId($id . '_right');
    if ($control_id) {
        $self->{text}->setId($control_id);
    } else {
        $self->{text}->setId($id . '_text');
    }
}

sub setAttribute {
    my ($self, $attr, $value) = @_;

    if ($attr eq 'id' || $attr eq 'class') {
        $self->SUPER::setAttribute($attr, $value);
        return $self;
    } else {
        $self->{text}->setAttribute($attr, $value);
	return $self;
    }
}

sub signalConnect {
    my ($self, $signal, $callback) = @_;

    $self->{text}->signalConnect($signal => $callback);
    return $self;
}

sub addClearButton {}
sub setPassword {}
sub isPassword {}
sub setText {}
sub getText {}
sub setDefaultText {}
sub getDefaultText {}
sub setAutoComplete {}

# Protected
#
sub _setupDefaultClass {
    my $self = shift;
    my $password = $self->{text}->getAttribute('type', 1);

    $self->prependClass($self->{_defaultClass});
    $self->{image1}->prependClass($self->{_defaultClass} . '_left');
    $self->{image2}->prependClass($self->{_defaultClass} . '_right');
    $self->{text}->prependClass($self->{_defaultClass} . '_text');
}

sub _realize {
    my $self    = shift;
    my $id      = $self->getId;

    $self->SUPER::_realize;
    my $options = toJSON($self->{_options});

    $self->_appendInitScript("IWL.Spinner.create('$id', $options);");
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $entry  = IWL::Input->new;
    my $image1 = IWL::Image->newFromStock('IWL_STOCK_GO_BACK');
    my $image2 = IWL::Image->newFromStock('IWL_STOCK_GO_FORWARD');

    $self->{image1} = $image1;
    $self->{image2} = $image2;
    $self->{text} = $entry;
    $self->{_defaultClass} = 'spinner';

    $self->appendChild($image1);
    $self->appendChild($entry);
    $self->appendChild($image2);

    $entry->setAttribute(type => 'text');

    $args{id} = randomize($self->{_defaultClass}) if !$args{id};
    $self->setClass($args{class}) if $args{class};
    $self->setId($args{id}) if $args{id};

    $self->{_options} = {value => 0, from => 0, to => 100,
        stepIncrement => 1.0, pageIncrement => 10.0,
        acceleration => 0.2, snap => 0, wrap => 0};

    $self->{_options}{to}            = $args{to}            if exists $args{to};
    $self->{_options}{from}          = $args{from}          if exists $args{from};
    $self->{_options}{value}         = $args{value}         if defined $args{value};
    $self->{_options}{stepIncrement} = $args{stepIncrement} if defined $args{stepIncrement};
    $self->{_options}{pageIncrement} = $args{pageIncrement} if defined $args{pageIncrement};
    $self->{_options}{acceleration}  = $args{acceleration}  if defined $args{acceleration};
    $self->{_options}{precision}     = $args{precision}     if defined $args{precision};
    $self->{_options}{mask}          = $args{mask}          if defined $args{mask};

    $self->{_options}{snap} = 1 if $args{snap};
    $self->{_options}{wrap} = 1 if $args{wrap};


    $entry->setAttribute(readonly => 1) if $args{readonly};
    $entry->setAttribute(maxlength => $args{maxlength}) if $args{maxlength};

    delete @args{qw(readonly maxlength password id class value to from
          stepIncrement pageIncrement acceleration precision mask snap wrap)};
    $self->requiredJs('base.js', 'entry.js', 'spinner.js');
    $entry->_constructorArguments(%args);

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
