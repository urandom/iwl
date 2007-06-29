#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Menu::Item;

use strict;

use base 'IWL::Container';

use IWL::String qw(randomize);
use IWL::Stock;
use IWL::Label;

=head1 NAME

IWL::Menu::Item - a menu item widget

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Container -> IWL::Menu::Item

=head1 DESCRIPTION

A menu item widget

=head1 CONSTRUCTOR

IWL::Menu::Item->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.
  - parentType - 'menu' (default) or 'menubar'

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new;

    $self->IWL::Menu::Item::__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setText> (B<TEXT>)

Sets the text for the menu item

Parameters: B<TEXT> - the text

=cut


sub setText {
    my ($self, $text) = @_;

    $self->{__label}->setText($text);

    return $self;
}

=item B<getText>

Returns the menu item text

=cut

sub getText {
    return shift->{__label}->getText;
}

=item B<setIcon> (B<ICON>)

Sets the icon of the menu item

Parameters: B<ICON> - a url, or a stock id for the icon

=cut

sub setIcon {
    my ($self, $icon) = @_;

    $icon = IWL::Stock->new()->getSmallImage($icon) if
      defined $icon && $icon =~ /^IWL_STOCK_/;
    $self->setStyle('background-image' => "url('$icon')") if $icon;
    return $self;
}

=item B<setType> ([B<TYPE>, B<GROUP>])

Sets the type of the menu item

Parameters: B<TYPE> - optional, type of the menu item:
  - none - regular menu item (default)
  - radio - a radio menu item
  - check - a check menu item

B<GROUP> - optional, the group of the radio item, if that type is used

=cut

sub setType {
    my ($self, $type, $group) = @_;

    return unless $type =~ /^(?:none|radio|check)$/;

    $self->{__type} = $type;
    if ($type eq 'radio') {
        $self->setName($group);
    }
    return $self;
}

=item B<getType>

Returns the menu item type

=cut

sub getType {
    return shift->{__type};
}

=item B<setSubmenu> (B<SUBMENU>)

Sets B<SUBMENU> as the submenu of the menu item

Parameters: B<SUBMENU> - an IWL::Menu

=cut

sub setSubmenu {
    my ($self, $submenu) = @_;

    return if $self->{__submenu};

    $self->appendChild($submenu);
    unless ($self->{__parentType} eq 'menubar') {
        $submenu->appendClass('submenu');
        $self->{__label}->appendClass('menu_label_parent');
    }
    return $self->{__submenu} = $submenu;
}

=item B<getSubmenu>

Returns the menu item's submenu

=cut

sub getSubmenu {
    return shift->{__submenu};
}

=item B<toggle> (B<BOOL>)

Toggles the menu item, if it's of time check or radio

Parameters: B<BOOL> - a boolean value, true if the item should be checked

=cut

sub toggle {
    my ($self, $bool) = @_;
    return unless $self->{__type} eq 'check' or $self->{__type} eq 'radio';

    $self->{__toggled} = $bool;

    return $self;
}

=item B<setDisabled> (B<BOOL>)

Sets whether the menu item is disabled or enabled

Parameters: B<BOOL> - true if the menu item should be disabled

=cut

sub setDisabled {
    my ($self, $bool) = @_;

    $self->removeClass('menu_item_disabled');
    $self->appendClass('menu_item_disabled') if $bool;

    return $self;
}

=item B<isDisabled>

Returns true if the menu item is disabled

=cut

sub isDisabled {
    return shift->hasClass('menu_item_disabled');
}

# Protected
#
sub _realize {
    my $self = shift;

    $self->SUPER::_realize;
    if ($self->{__type} eq 'check') {
        $self->appendClass('menu_check_item');
        $self->appendClass('menu_check_item_checked') if $self->{__toggled};
    } elsif ($self->{__type} eq 'radio') {
        $self->appendClass('menu_radio_item');
        $self->appendClass('menu_radio_item_checked') if $self->{__toggled};
    }

    return $self;
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $label = $self->{__label} = IWL::Label->new;
    my $parentType = $args{parentType} || 'menu';
    $self->{_defaultClass} = $parentType eq 'menubar' ? 'menubar_item' : 'menu_item';
    $args{id} = randomize($self->{_defaultClass}) if !$args{id};
    delete @args{qw(parentType)};

    $self->_constructorArguments(%args);
    $self->appendChild($label);
    $self->{_tag} = 'li';

    $self->{__type} = 'none';
    $self->{__parentType} = $parentType;
    if ($parentType eq 'menubar') {
        $label->setClass('menubar_label');
    } else {
        $label->setClass('menu_label');
    }
    $self->{_customSignals} = {change => [], select => [], unselect => []};
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
