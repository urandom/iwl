#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Menu;

use strict;

use base 'IWL::List';

use IWL::String qw(randomize);
use IWL::JSON qw(toJSON);
use IWL::Menu::Item;

use Locale::TextDomain qw(org.bloka.iwl);

=head1 NAME

IWL::Menu - a menu widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container> -> L<IWL::List> -> L<IWL::Menu>

=head1 DESCRIPTION

A popup menu widget

=head1 CONSTRUCTOR

IWL::Menu->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=head1 SIGNALS

=over 4

=item B<menu_item_activate>

Fires when a menu item has been activated, via double clicking. Receives the activated item as a parameter

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

=item B<appendMenuItem> (B<TEXT>, [B<URL>, B<%ARGS>])

Appends text as a menu item to the current menu

Parameters: B<TEXT> - the text, B<URL> - the url of the item icon (if it's not of type 'radio' or 'check'). It can also be a stock icon id, B<%ARGS> - the hash attributes of the menu item

=cut

sub appendMenuItem {
    my ($self, $text, $url, %args) = @_;
    my $mi = IWL::Menu::Item->new(%args);

    $self->appendChild($mi);
    $mi->setText($text);
    $mi->setIcon($url);
    push @{$self->{__menuItems}}, $mi;
    return $mi;
}

=item B<prependMenuItem> (B<TEXT>, [B<URL>, B<%ARGS>])

Prepends text as a menu item to the current menu

Parameters: B<TEXT> - the text, B<URL> - the url of the item icon. It can also be a stock icon id, B<%ARGS> - the hash attributes of the menu item

=cut

sub prependMenuItem {
    my ($self, $text, $url, %args) = @_;
    my $mi = IWL::Menu::Item->new(%args);

    $self->prependChild($mi);
    $mi->setText($text);
    $mi->setIcon($url);
    unshift @{$self->{__menuItems}}, $mi;
    return $mi;
}

=item B<appendMenuSeparator>

Appends a separator to the menu

=cut

sub appendMenuSeparator {
    my $self = shift;
    my $mi = $self->__setup_menu_separator;

    $self->appendChild($mi);
    return $mi;
}

=item B<prependMenuSeparator>

Prepends a separator to the menu

=cut

sub prependMenuSeparator {
    my $self = shift;
    my $mi = $self->__setup_menu_separator;

    $self->prependChild($mi);
    return $mi;
}

=item B<bindToWidget> (B<WIDGET>, B<SIGNAL>)

Binds the menu to pop up when the specified widget emits the given signal

Parameters: B<WIDGET> - the widget to bind to, B<SIGNAL> - the signal the widget will emit to pop up the menu

Note: The widget ID must not be changed after this method is called.

=cut

sub bindToWidget {
    my ($self, $widget, $signal) = @_;
    my $id = $widget->getId;
    return $self->_pushError(__("Invalid id")) unless $id;
    push @{$self->{__bindWidgets}}, [$id => $widget->_namespacedSignalName($signal)];

    return $self;
}

=item B<setMaxHeight> (B<HEIGHT>)

Sets the max height of the menu, after which it will become a scrollable menu

Parameters: B<HEIGHT> - the desired max height of the menu (in pixels). Setting this parameter to 0 will turn the option off

=cut

sub setMaxHeight {
    my ($self, $height) = @_;

    if ($height > 0) {
	$self->{_options}{maxHeight} = $height;
    } else {
	$self->{_options}{maxHeight} = 0;
    }
    return $self;
}

=item B<getMaxHeight>

Returns the max height of the menu

=cut

sub getMaxHeight {
    return shift->{_options}{maxHeight};
}

# Protected
#
sub _realize {
    my $self    = shift;
    my $id      = $self->getId;
    my $options = toJSON($self->{_options});
    my $script;

    $self->SUPER::_realize;
    $script = "var menu = IWL.Menu.create('$id', $options);";
    foreach my $bind (@{$self->{__bindWidgets}}) {
        $script .= qq{menu.bindToWidget('$bind->[0]', '$bind->[1]');};
    }
    return $self->_appendInitScript($script);
}

sub _init {
    my ($self, %args) = @_;

    $self->SUPER::_init(%args);
    $self->{_defaultClass} = 'menu';
    $args{id} = randomize($self->{_defaultClass}) if !$args{id};
    $self->_constructorArguments(%args);
    $self->requiredJs('base.js', 'menu.js');
    $self->{_customSignals} = {menu_item_activate => []};
    $self->{_options} = {maxHeight => 0};
    $self->{__bindWidgets} = [];
}

# Internal
#
sub __setup_menu_separator {
    my $self = shift;
    my $mi = IWL::Widget->new;
    my $text = IWL::Text->new('&nbsp;');

    $mi->{_tag} = 'li';
    $mi->{_defaultClass} = 'menu_separator';
    $mi->setId(randomize('menu_item'));
    $mi->appendChild($text);

    return $mi;
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
