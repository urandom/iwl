#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::PageControl;

use strict;

use base 'IWL::Container';

use Locale::TextDomain qw(org.bloka.iwl);
use IWL::String qw(randomize);
use JSON;

=head1 NAME

IWL::PageControl - a page control widget

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Container -> IWL::PageControl

=head1 DESCRIPTION

A page control widget for page-capable widgets

=head1 CONSTRUCTOR

IWL::PageControl->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new;

    $self->IWL::PageControl::__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<bindToWidget> (B<WIDGET>, B<URL>, B<PARAMS>)

Binds the widget to the page control and automatically registers a 'refresh' event for it

Parameters: B<WIDGET> - the widget to bind to, B<URL> - the url that will process the created event, B<PARAMS> - the user parameters

Note: The widget id must not be changed after this method is called.

=cut

sub bindToWidget {
    my ($self, $widget, $url, $params) = @_;

    return unless $widget && $widget->can('registerEvent');

    my $event_name = ref($widget) . "::refresh";
    $event_name =~ s/::/-/g;
    $self->{__bind}{eventName} = $event_name;
    $self->{__bind}{widgetId} = $widget->getId;
    $self->{__options}{bound} = 1;

    $widget->registerEvent($event_name, $url, $params);
    return $self;
}

=item B<isBound>

Returns whether the page control is bound to a widget

=cut

sub isBound {
    my $self = shift;

    return $self->{__options}{bound};
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
    my $self = shift;
    my $script = IWL::Script->new;
    my $id = $self->getId;
    my $options = objToJson($self->{__options});

    $self->setStyle(display => 'none');
    $self->SUPER::_realize;
    $script->appendScript("PageControl.create('$id', $options);");
    $script->appendScript("\$('$id').bindToWidget('$self->{__bind}{widgetId}', '$self->{__bind}{eventName}');")
	if $self->{__options}{bound};
    return $self->_appendAfter($script);
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

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $label = IWL::Label->new;
    my $page_count = IWL::Label->new->appendText($args{pageCount});
    my $page_entry = IWL::Entry->new->setSize(2);
    my ($first, $prev, $next, $last) = IWL::Button->newMultiple(
	{size => 'medium'}, {size => 'medium'}, {size => 'medium'}, {size => 'medium'});

    $self->{_defaultClass} = 'pagecontrol';
    $args{id} = randomize($self->{_defaultClass}) if !$args{id};

    # TRANSLATORS: 
    my $info = __x("{PAGEENTRY} of {PAGECOUNT}", 
		    PAGEENTRY => 'PAGEENTRY', PAGECOUNT => 'PAGECOUNT');
    my ($pre, $post) = $info =~ m{^(.*)PAGEENTRY(.*)$};
    if ($pre =~ m{^(.*)PAGECOUNT(.*)$}) {
	$label->appendText($1)->appendChild($page_count)->appendChild($2);
    } else {
	$label->appendText($pre);
    }
    $label->appendChild($page_entry);
    if ($post =~ m{^(.*)PAGECOUNT(.*)$}) {
	$label->appendText($1)->appendChild($page_count)->appendChild($2);
    } else {
	$label->appendText($post);
    }

    $self->{__first} = $first->setImage('IWL_STOCK_GOTO_FIRST');
    $self->{__prev}  = $prev->setImage('IWL_STOCK_GO_BACK');
    $self->{__next}  = $next->setImage('IWL_STOCK_GO_FORWARD');
    $self->{__last}  = $last->setImage('IWL_STOCK_GOTO_LAST');
    $self->{__label} = $label;
    $self->{__pageCount} = $page_count;
    $self->{__pageEntry} = $page_entry;

    $self->appendChild($first, $prev, $label, $next, $last);

    $self->{__options} = {};
    $self->{__options}{pageCount} = $args{pageCount};
    $self->{__options}{pageSize} = $args{pageSize};

    $self->{__bind}{bound} = 0;
    delete @args{qw(pageCount pageSize)};

    $self->{_customSignals} = {load => [], current_page_is_changing => [], current_page_change => []};
    $self->_constructorArguments(%args);
    $self->requiredJs('base.js', 'pagecontrol.js');
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
