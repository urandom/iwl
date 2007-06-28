#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Notebook;

use strict;

use base 'IWL::Container';

use IWL::List;
use IWL::Label;
use IWL::Notebook::Tab;
use IWL::String qw(randomize);

=head1 NAME

IWL::Notebook - a tabbed notebook widget

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Container -> IWL::Notebook

=head1 DESCRIPTION

The notebook widget provided a way to group content in tabs

=head1 CONSTRUCTOR

IWL::Notebook->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->{_noChildren} = 0;

    # The list of pages
    $self->{__tabs} = [];

    $self->__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<appendTab> (B<TEXT>, [B<OBJECT>, B<SELECTED>])

Appends a new tab and adds the object to the tab page

Parameter: B<OBJECT> - the IWL::Object(3pm) to be appended, B<TEXT> - the text for the tab label, B<SELECTED> - true if the tab should be the selected one

=cut

sub appendTab {
    my ($self, $text, $object, $selected) = @_;
    return $self->__setup_page($object, $text, $selected);
}

=item B<prependTab> (B<TEXT>, [B<OBJECT>, B<SELECTED>])

Prepends a new tab and adds the object to the tab page

Parameter: B<OBJECT> - the IWL::Object(3pm) to be prepended, B<TEXT> - the text for the tab label, B<SELECTED> - true if the tab should be the selected one

=cut

sub prependTab {
    my ($self, $text, $object, $selected) = @_;
    return $self->__setup_page($object, $text, $selected, 1);
}

# Overrides
#
sub setId {
    my ($self, $id) = @_;

    $self->SUPER::setId($id);
    $self->{__navgroup}->setId($id . '_navgroup');
    $self->{__navborder}->setId($id . '_navborder');
    $self->{__content}->setId($id . '_content');
    $self->{__mainnav}->setId($id . '_mainnav');
    $self->{__clear}->setId($id . '_clear');

    return $self;
}

# Protected
#
sub _realize {
    my $self     = shift;
    my $script   = IWL::Script->new;
    my $id       = $self->getId;
    my $selected = 0;

    $self->SUPER::_realize;
    foreach my $tab (@{$self->{__tabs}}) {
        last if $selected = $tab->isSelected;
    }
    $self->{__tabs}[0]->setSelected(1) if !$selected;
    $script->setScript("Notebook.create('$id');");
    $self->_appendAfter($script);
}

sub _registerEvent {
    my ($self, $event, $params) = @_;

    my $handlers = {};
    if ($event eq 'IWL-Notebook-Tab-add') {
	return $handlers;
    } else {
	$self->SUPER::_registerEvent($event, $params);
    }

    return $handlers;
}

sub _setupDefaultClass {
    my $self = shift;

    $self->SUPER::prependClass($self->{_defaultClass});
    $self->{__navgroup}->prependClass($self->{_defaultClass} . '_navgroup');
    $self->{__navborder}->prependClass($self->{_defaultClass} . '_navborder');
    $self->{__content}->prependClass($self->{_defaultClass} . '_content');
    $self->{__mainnav}->prependClass($self->{_defaultClass} . '_mainnav');
    $self->{__clear}->prependClass($self->{_defaultClass} . '_clear');

    return $self;
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $navgroup  = IWL::Container->new;
    my $navborder = IWL::Container->new;
    my $content   = IWL::Container->new;
    my $mainnav   = IWL::List->new;
    my $clear     = IWL::Break->new;

    $self->{__navgroup}  = $navgroup;
    $self->{__navborder} = $navborder;
    $self->{__content}   = $content;
    $self->{__mainnav}   = $mainnav;
    $self->{__clear}     = $clear;
    $self->appendChild($navgroup);
    $self->appendChild($navborder);
    $self->appendChild($content);
    $navgroup->appendChild($mainnav);
    $navgroup->appendChild($clear);

    $self->{_defaultClass} = 'notebook';
    $args{id} = randomize($self->{_defaultClass}) if !$args{id};

    $self->_constructorArguments(%args);
    $self->requiredJs('base.js', 'notebook.js');
    $self->{_customSignals} = {current_tab_change => []};

    return $self;
}

sub __setup_page {
    my ($self, $object, $text, $selected, $reverse) = @_;
    my $tab = IWL::Notebook::Tab->new;
    my $index;

    $tab->appendPage($object);
    if ($reverse) {
	$index = unshift @{$self->{__tabs}}, $tab;
    } else {
	$index = push @{$self->{__tabs}}, $tab;
    }

    $tab->setSelected($selected) if $object;
    $tab->setTitle($text);

    if ($reverse) {
	$self->{__mainnav}->prependChild($tab);
	$self->{__content}->prependChild($tab->{_page});
    } else {
	$self->{__mainnav}->appendChild($tab);
	$self->{__content}->appendChild($tab->{_page});
    }

    return $tab;
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
