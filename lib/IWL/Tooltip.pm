#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Tooltip;

use strict;

use base qw(IWL::Script IWL::Widget);

use IWL::String qw(escape randomize);
use JSON;

=head1 NAME

IWL::Tooltip - a tooltip widget

=head1 INHERITANCE

L<IWL::Object> -> L<IWL::Script> -> L<IWL::Tooltip>
L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Tooltip>

=head1 DESCRIPTION

The tooltip widget provides a balloon type tooltip. It is generated in javascript

=head1 CONSTRUCTOR

IWL::Tooltip->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values:

=over 4

=item B<centerOnElement>

True, if the tooltip should appear in the center of the bound element

=item B<followMouse>

True, if the tooltip should follow the mouse

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<bindToWidget> (B<WIDGET>, B<SIGNAL>)

Binds the tooltip to show when the specified widget emits the given signal.

Parameters: B<WIDGET> - the widget to bind to, B<SIGNAL> - the signal the widget will emit to show the tooltip 

Note: The tooltip and widget ids must not be changed after this method is called.

=cut

sub bindToWidget {
    my ($self, $widget, $signal) = @_;
    my $to = $widget->getId;

    $self->{__bound} = $to;
    $self->{__bindSignal} = $signal;
    return $self;
}

=item B<bindHideToWidget> (B<WIDGET>, B<SIGNAL>)

Binds the tooltip to hide when the specified widget emits the given signal.

Parameters: B<WIDGET> - the widget to bind to, B<SIGNAL> - the signal the widget will emit to hide the tooltip 

Note: The tooltip and widget ids must not be changed after this method is called.

=cut

sub bindHideToWidget {
    my ($self, $widget, $signal) = @_;
    my $to = $widget->getId;

    $self->{__boundHide} = $to;
    $self->{__bindHideSignal} = $signal;
    return $self;
}

=item B<setContent> (B<CONTENT>)

Sets the content of the tooltip

Parameters: B<CONTENT> - text or widget to add as the content of the tooltip

=cut

sub setContent {
    my ($self, $content) = @_;
    if (UNIVERSAL::isa($content, 'IWL::Widget')) {
        if ($content->{_requiredJs}) {
            push @{$self->{_requiredJs}}, @{$content->{_requiredJs}};
            $content->{_requiredJs} = [];
        }
	$self->{__content} = escape($content->getContent);
    } else {
	$self->{__content} = escape($content);
    }
    return $self;
}

# Protected
#
sub _realize {
    my $self = shift;
    my $id   = $self->getId;
    my $options;

    $self->{_options}{hidden} = 1;

    $options = objToJson($self->{_options});
    $self->setId($id . '_script');
    $self->SUPER::_realize;
    $self->setScript("Tooltip.create('$id', $options);");
    $self->appendScript("\$('$id').setContent('$self->{__content}')") if $self->{__content};
    $self->appendScript("\$('$id').bindToWidget('$self->{__bound}', '$self->{__bindSignal}');")
      if $self->{__bound};
    $self->appendScript("\$('$id').bindHideToWidget('$self->{__boundHide}', '$self->{__bindHideSignal}');")
      if $self->{__boundHide};
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    $self->{_defaultClass} = 'tooltip';

    $self->{_options} = {};
    $self->{_options}{centerOnElement} = !(!$args{centerOnElement}) if defined $args{centerOnElement};
    $self->{_options}{followMouse}     = !(!$args{followMouse})     if defined $args{followMouse};

    $args{id} ||= randomize($self->{_defaultClass});
    $self->{_tag} = "script";

    delete @args{qw(centerOnElement followMouse)};
    $self->_constructorArguments(%args);
    $self->requiredJs('base.js', 'tooltip.js');

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
