#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Menubar;

use strict;

use base 'IWL::List';

use IWL::Menu::Item;
use IWL::String qw(randomize);

=head1 NAME

IWL::Menubar - a menubar widget

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Container -> IWL::List -> IWL::Menubar

=head1 DESCRIPTION

A menubar widget

=head1 CONSTRUCTOR

IWL::Menubar->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new;

    $self->IWL::Menubar::__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<appendMenuItem> (B<TEXT>, [B<URL>, B<%ARGS>])

Appends text as a menu item to the current menubar

Parameters: B<TEXT> - the text, B<URL> - the url of the item icon, B<%ARGS> - the hash attributes of the menu item

=cut

sub appendMenuItem {
    my ($self, $text, $url, %args) = @_;
    my $mi = IWL::Menu::Item->new(parentType => 'menubar', %args);

    $self->appendChild($mi);
    $mi->setText($text);
    $mi->setIcon($url);
    return $mi;
}

=item B<prependMenuItem> (B<TEXT>, [B<URL>, B<%ARGS>])

Prepends text as a menu item to the current menubar

Parameters: B<TEXT> - the text, B<URL> - the url of the item icon, B<%ARGS> - the hash attributes of the menu item

=cut

sub prependMenuItem {
    my ($self, $text, $url, %args) = @_;
    my $mi = IWL::Menu::Item->new(parentType => 'menubar', %args);

    $self->prependChild($mi);
    $mi->setText($text);
    $mi->setIcon($url);
    return $mi;
}

=item B<appendMenuSeparator>

Appends a separator to the menubar

=cut

sub appendMenuSeparator {
    my $self = shift;
    my $mi = $self->__setup_menu_separator;

    $self->appendChild($mi);
    return $mi;
}

=item B<prependMenuSeparator>

Prepends a separator to the menubar

=cut

sub prependMenuSeparator {
    my $self = shift;
    my $mi = $self->__setup_menu_separator;

    $self->prependChild($mi);
    return $mi;
}

=item B<mouseOverActivationSet> (B<BOOL>)

Sets whether the child menus of the menubar should pop up on mouse over or not

Parameters: B<BOOL> - true if the submenus should pop up on mouse over

=cut

sub mouseOverActivationSet {
    my ($self, $bool) = @_;

    if ($bool) {
      $self->{__mouseOverActivation} = 1;
    } else {
      $self->{__mouseOverActivation} = 0;
    }
    return $self;
}

# Protected
#
sub _realize {
    my $self = shift;
    my $script = IWL::Script->new;
    my $id = $self->getId;
    my $options = '';

    $self->SUPER::_realize;
    if ($self->{__mouseOverActivation}) {
	$options .= "mouseOverActivation: true";
    } else {
	$options .= "mouseOverActivation: false";
    }
    $script->appendScript("Menu.create('$id', {$options});");
    return $self->_appendAfter($script);
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    $self->{_defaultClass} = 'menubar';
    $args{id} = randomize($self->{_defaultClass}) if !$args{id};

    $self->_constructorArguments(%args);
    $self->requiredJs('base.js', 'menu.js');
}

sub __setup_menu_separator {
    my $self = shift;
    my $mi = IWL::Widget->new;
    my $text = IWL::Text->new('&nbsp;');

    $mi->{_tag} = 'li';
    $mi->{_defaultClass} = 'menubar_separator';
    $mi->setId(randomize('menubar_item'));
    $mi->appendChild($text);

    return $mi;
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
