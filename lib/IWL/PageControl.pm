#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::PageControl;

use strict;

use base 'IWL::Container';

use IWL::String qw(randomize);
use IWL::Label;
use IWL::Entry;
use IWL::Button;
use IWL::JSON qw(toJSON);

use IWL::Config '%IWLConfig';
use Locale::TextDomain $IWLConfig{TEXT_DOMAIN};

=head1 NAME

IWL::PageControl - a page control widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container> -> L<IWL::PageControl>

=head1 DESCRIPTION

A page control widget for page-capable widgets

=head1 CONSTRUCTOR

IWL::PageControl->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=head1 SIGNALS

=over 4

=item B<load>

Fires when the pagecontrol has finished loading

=item B<current_page_is_changing>

Fires when the current page of the pagecontrol begins to change

=item B<current_page_change>

Fires when the current page of the pagecontrol has changed

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

=item B<bindToWidget> (B<WIDGET>, B<URL>, [B<PARAMS>, B<OPTIONS>])

Binds the widget to the page control and automatically registers a 'refresh' event for it

Parameters: B<WIDGET> - the widget to bind to, B<URL> - the url that will process the created event, B<PARAMS> - the user parameters, B<OPTIONS> - event options

Note: The widget id must not be changed after this method is called.

=cut

sub bindToWidget {
    my ($self, $widget, $url, $params, $options) = @_;
    my $id = $widget->getId;

    return unless $widget && $widget->can('registerEvent') && $id;

    my $event_name = ref($widget) . "::refresh";
    $event_name =~ s/::/-/g;
    $self->{__bind}{eventName} = $event_name;
    $self->{__bind}{widgetId} = $id;
    $self->{__options}{bound} = 1;

    $widget->registerEvent($event_name, $url, $params, $options);
    return $self;
}

=item B<isBound>

Returns whether the page control is bound to a widget

=cut

sub isBound {
    return !(!shift->{__options}{bound});
}

# Overrides
#
sub setId {
    my ($self, $id) = @_;
    $self->SUPER::setId($id);
    $self->{__first}->setId($id . '_first');
    $self->{__prev}->setId($id . '_prev');
    $self->{__next}->setId($id . '_next');
    $self->{__last}->setId($id . '_last');
    $self->{__label}->setId($id . '_label');
    $self->{__pageCount}->setId($id . '_page_count');
    $self->{__pageEntry}->setId($id . '_page_entry');

    return $self;
}

# Protected
#
sub _realize {
    my $self    = shift;
    my $id      = $self->getId;
    my $options = toJSON($self->{__options});
    my $script;

    $self->setStyle(display => 'none');
    $self->SUPER::_realize;
    $script = "IWL.PageControl.create('$id', $options);";
    $script .= "\$('$id').bindToWidget('$self->{__bind}{widgetId}', '$self->{__bind}{eventName}');"
	if $self->{__options}{bound};
    return $self->_appendInitScript($script);
}

sub _setupDefaultClass {
    my ($self) = @_;

    $self->SUPER::prependClass($self->{_defaultClass});
    $self->{__first}->prependClass($self->{_defaultClass} . "_first");
    $self->{__prev}->prependClass($self->{_defaultClass} . "_prev");
    $self->{__next}->prependClass($self->{_defaultClass} . "_next");
    $self->{__last}->prependClass($self->{_defaultClass} . "_last");
    $self->{__label}->prependClass($self->{_defaultClass} . "_label");
    $self->{__pageCount}->prependClass($self->{_defaultClass} . "_page_count");
    $self->{__pageEntry}->prependClass($self->{_defaultClass} . "_page_entry");
}

sub _init {
    my ($self, %args) = @_;
    my $label = IWL::Container->new;
    my $page_count = IWL::Label->new->appendText($args{pageCount});
    my $page_entry = IWL::Entry->new->setSize(2);
    my ($first, $prev, $next, $last) = IWL::Button->newMultiple(
	{size => 'medium'}, {size => 'medium'}, {size => 'medium'}, {size => 'medium'});

    $self->{_defaultClass} = 'pagecontrol';
    $args{id} = randomize($self->{_defaultClass}) if !$args{id};

    # TRANSLATORS: {PAGEENTRY} and {PAGECOUNT} are placeholders
    my $info = __"{PAGEENTRY} of {PAGECOUNT}";
    my ($pre, $post) = $info =~ m{^(.*){PAGEENTRY}(.*)$};
    if ($pre =~ m{^(.*){PAGECOUNT}(.*)$}) {
        $label->appendChild(IWL::Label->new->setText($1))->appendChild($page_count)->appendChild($2);
    } else {
        $label->appendChild(IWL::Label->new->setText($pre));
    }
    $label->appendChild($page_entry);
    if ($post =~ m{^(.*){PAGECOUNT}(.*)$}) {
        $label->appendChild(IWL::Label->new->setText($1))->appendChild($page_count)->appendChild($2);
    } else {
        $label->appendChild(IWL::Label->new->setText($post));
    }

    $self->{__first} = $first->setImage('IWL_STOCK_GOTO_FIRST');
    $self->{__prev}  = $prev->setImage('IWL_STOCK_GO_BACK');
    $self->{__next}  = $next->setImage('IWL_STOCK_GO_FORWARD');
    $self->{__last}  = $last->setImage('IWL_STOCK_GOTO_LAST');
    $self->{__label} = $label;
    $self->{__pageCount} = $page_count;
    $self->{__pageEntry} = $page_entry;

    $self->appendChild($first, $prev, $label, $next, $last, IWL::Container->new(class => 'iwl-clear'));

    $self->{__options} = {};
    $self->{__options}{pageCount} = $args{pageCount};
    $self->{__options}{pageSize} = $args{pageSize};
    $self->{__options}{page} = $args{page} || 1;

    $self->{__bind}{bound} = 0;
    delete @args{qw(pageCount pageSize)};

    $self->{_customSignals} = {load => [], current_page_is_changing => [], current_page_change => []};
    $self->_constructorArguments(%args);
    $self->requiredJs('base.js', 'pagecontrol.js');
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
