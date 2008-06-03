#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::ProgressBar;

use strict;

use base 'IWL::Container';

use IWL::Label;
use IWL::String qw(randomize);
use IWL::JSON qw(toJSON);

=head1 NAME

IWL::ProgressBar - a visual progress indicator

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container> -> L<IWL::ProgressBar>

=head1 DESCRIPTION

The progress bar widget is used to visually prepresent the status of an operation.

=head1 CONSTRUCTOR

IWL::ProgressBar->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<value>

The initial value of the progress bar. Defaults to I<0.0>

=item B<text>

The text of the progress bar. Defaults to I<''>

=item B<pulsate>

Boolean, true if the progress bar should pulsate. Defaults to I<''>

=back

=head1 SIGNALS

=over 4

=item B<load>

Fires when the progress bar has finished loading

=item B<change>

Fires when the progress bar value has changed

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new;

    $self->_init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setValue> (B<VALUE>)

Sets the value of the progress bar

Parameters: B<VALUE> - a float value, between 0 and 1, indicating the overall progress

=cut

sub setValue {
    my ($self, $value) = @_;

    $self->{_options}{value} = $value;
    return $self;
}

=item B<getValue>

Returns the value of the progress bar

=cut

sub getValue {
    return shift->{_options}{value};
}

=item B<setText> (B<TEXT>)

Sets the text of the progress bar.

Parameters: B<TEXT> - a text string. If the string contains I<#{percent}>, that portion will be replaced by the percentage value of the spinner

=cut

sub setText {
    my ($self, $text) = @_;

    $self->{_options}{text} = $text;
    return $self;
}

=item B<getText>

Returns the text of the progress bar

=cut

sub getText {
    return shift->{_options}{text};
}

=item B<setPulsate> (B<BOOL>)

Sets whether the progress bar should continuously pulsate to indicate uncountable progress_bar

Parameters: B<BOOL> - if true, the progress bar should pulsate

=cut

sub setPulsate {
    my ($self, $bool) = @_;

    $self->{_options}{pulsate} = !(!$bool);
    return $self;
}

=item B<isPulsating>

Returns whether the progress bar is pulsating

=cut

sub isPulsating {
    return shift->{_options}{pulsate};
}

# Protected
#
sub _setupDefaultClass {
    my $self = shift;

    $self->prependClass($self->{_defaultClass});
    $self->{__block}->prependClass($self->{_defaultClass} . '_block');
    $self->{__label}->prependClass($self->{_defaultClass} . '_label');
}

sub _realize {
    my $self    = shift;
    my $id      = $self->getId;

    $self->SUPER::_realize;
    my $options = toJSON($self->{_options});

    $self->_appendInitScript("IWL.ProgressBar.create('$id', $options);");
}

sub _init {
    my ($self, %args) = @_;
    my $block = IWL::Container->new;
    my $label = IWL::Label->new(expand => 1);

    $self->{_defaultClass} = 'progress_bar';
    $self->{__block} = $block;
    $self->{__label} = $label->setText;

    $self->appendChild($block, $label);

    $args{id} = randomize($self->{_defaultClass}) if !$args{id};

    $self->{_options} = {};
    $self->{_options}{value}   = $args{value}       if defined $args{value};
    $self->{_options}{text}    = $args{text}        if defined $args{text};
    $self->{_options}{pulsate} = !(!$args{pulsate}) if defined $args{pulsate};

    delete @args{qw(value text pulsate)};
    $self->requiredJs('base.js', 'scriptaculous_extensions.js', 'progressbar.js');
    $self->_constructorArguments(%args);
    $self->{_customSignals} = {load => [], change => []};

    return $self;
}

1;

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2008  Viktor Kojouharov. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
