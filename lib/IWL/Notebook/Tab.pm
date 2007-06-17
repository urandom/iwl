#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Notebook::Tab;

use strict;

use base qw(IWL::Widget);

use JSON;
use IWL::String qw(randomize);

=head1 NAME

IWL::Notebook::Tab - a tab used in a notebook

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Notebook::Tab

=head1 DESCRIPTION

The notebook tab widget is a helper widget used by the IWL::Notebook(3pm)

=head1 CONSTRUCTOR

IWL::Notebook::Tab->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

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

=item B<appendPage> (B<OBJECT>)

Appends the object to the page of a tab

Parameter: B<OBJECT> - the IWL::Object(3pm) to be appended

=cut

sub appendPage {
    my ($self, $object) = @_;

    $self->{_page}->appendChild($object);
    return $self;
}

=item B<prependPage> (B<OBJECT>)

Prepends the object to the page of a tab

Parameter: B<OBJECT> - the IWL::Object(3pm) to be prepended 

=cut

sub prependPage {
    my ($self, $object) = @_;

    $self->{_page}->prependChild($object);
    return $self;
}

=item B<setTitle> (B<TEXT>)

Sets the title of the tab label

Parameters: B<TEXT> - the text of the tab label

=cut

sub setTitle {
    my ($self, $text) = @_;

    $self->{__anchor}->setText($text);
    return $self;
}

=item B<setSelected> (B<BOOL>)

Sets whether the tab is the currently selected tab

Parameters: B<BOOL> - true if the tab should be the currently selected one

=cut

sub setSelected {
    my ($self, $bool) = @_;

    $self->{__selected} = $bool ? 1 : 0;
    return $self;
}

# Overrides
#
sub setId {
    my ($self, $id) = @_;
    my $page_id = $id;

    $page_id .= '_page' unless $page_id =~ s/tab/page/g;
    $self->SUPER::setId($id);
    $self->{__anchor}->setId($id . '_anchor');
    $self->{_page}->setId($page_id);

    return $self;
}

# Protected
#
sub _setupDefaultClass {
    my $self = shift;

    if ($self->{__selected}) {
	$self->SUPER::prependClass($self->{_defaultClass} . '_selected');
	$self->{_page}->prependClass('notebook_page_selected');
    }
    $self->SUPER::prependClass($self->{_defaultClass});
    $self->{_page}->prependClass('notebook_page');
    $self->{__anchor}->prependClass($self->{_defaultClass} . '_anchor');
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $page = IWL::Container->new;
    my $anchor = IWL::Anchor->new;

    $self->{_tag} = 'li';
    $self->{_defaultClass} = 'notebook_tab';
    $args{id} = randomize($self->{_defaultClass}) if !$args{id};

    $self->{_page} = $page;
    $self->{__anchor} = $anchor;
    $self->appendChild($anchor);

    $self->_constructorArguments(%args);

    $self->{_customSignals} = {select => [], unselect => [], remove => []};
    $self->{__selected} = 0;
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
