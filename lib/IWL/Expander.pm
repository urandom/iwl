#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Expander;

use strict;

use base 'IWL::Container';

=head1 NAME

IWL::Expander - a container which can hide its children

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container> -> L<IWL::Expander>

=head1 DESCRIPTION

The expander widget is is a specialized container, which can show and hide its children depending on user input

=head1 CONSTRUCTOR

IWL::Expander->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values

=over 4

=item B<expanded>

If true, the initial state of the expander will be expanded. Defaults to B<false>

=item B<label>

The label of the expander. Defaults to B<''>

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

=item B<setExpanded> (B<BOOL>)

Sets whether the expander should be expanded

Parameters: B<BOOL> - if true, the expander should be expanded

=cut

sub setExpanded {
    my ($self, $bool) = @_;
    $self->{_options}{expanded} = !(!$bool);
    return $self;
}

=item B<getExpanded>

Returns whether the expander is expanded

=cut

sub getExpanded {
    return shift->{_options}{expanded};
}

=item B<setLabelWidget> (B<WIDGET>)

Sets the given widget as a label for the expander

Parameters: B<WIDGET> - an L<IWL::Widget>

=cut

sub setLabelWidget {
    my ($self, $widget) = @_;
    $self->{__label}->appendChild($widget);

    return $self;
}

=item B<getLabelWidget>

Returns the current label widget, if any

=cut

sub getLabelWidget {
    return shift->{__label}{childNodes}[0];
}

=item B<setLabel> (B<TEXT>)

Sets the given text as the text for the label

Parameters: B<TEXT> - the text for the label

=cut

sub setLabel {
    my ($self, $text) = @_;

    $self->{_options}{label} = $text;
    return $self;
}

=item B<getLabel>

Returns the current label text

=cut

sub getLabel {
    return shift->{_options}{label};
}

# Overrides
#
sub appendChild {
    my ($self, @children) = @_;
    $self->{__content}->appendChild(@children);

    return $self;
}

sub prependChild {
    my ($self, @children) = @_;
    $self->{__content}->prependChild(@children);

    return $self;
}

sub setChild {
    my $self = shift;
    $self->{__content}->setChild(@_);

    return $self;
}

sub insertAfter {
    my $self = shift;
    $self->{__content}->insertAfter(@_);

    return $self;
}

# Protected
#
sub _realize {
    my $self = shift;

    $self->SUPER::_realize;
    $self->{__label}->appendChild(IWL::Text->new($self->{_options}{label}))
      if $self->{_options}{label};
    if (!$self->{_options}{expanded}) {
        $self->{__content}->setStyle(display => 'none');
        $self->appendClass('expander_collapsed');
    }
    $self->{__header}->signalConnect(click =>
          "new Effect.toggle(\$(this).next('.expander_content'), 'blind', {duration: 0.25, afterFinish: function() {this.toggleClassName('expander_collapsed')}.bind(\$(this).up())})");
    $self->{__header}->signalConnect(mouseover => "\$(this).addClassName('expander_header_hover')");
    $self->{__header}->signalConnect(mouseout => "\$(this).removeClassName('expander_header_hover')");
}

sub _init {
    my ($self, %args) = @_;
    my ($header, $icon, $label, $content) = IWL::Container->newMultiple(4);

    $self->{_defaultClass}      = 'expander';
    $self->{_options}           = {};
    $self->{_options}{label}    = $args{label} || '';
    $self->{_options}{expanded} = !(!$args{expanded}) if exists $args{expanded};
    delete @args{qw(label expanded)};

    $icon->{_defaultClass}    = 'expander_icon';
    $label->{_defaultClass}   = 'expander_label';
    $header->{_defaultClass}  = 'expander_header';
    $content->{_defaultClass} = 'expander_content';

    $self->{__icon}    = $icon;
    $self->{__label}   = $label;
    $self->{__header}  = $header;
    $self->{__content} = $content;

    $self->SUPER::appendChild($header, $content);
    $header->appendChild($icon, $label);

    $self->_constructorArguments(%args);
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
