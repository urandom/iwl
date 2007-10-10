#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Accordion::Page;

use strict;

use base qw(IWL::Container);

use JSON;
use IWL::String qw(randomize);

=head1 NAME

IWL::Accordion::Page - a page used in a accordion

=head1 INHERITANCE

L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container> -> L<IWL::Accordion::Page>

=head1 DESCRIPTION

The accordion page widget is a helper widget used by the IWL::Accordion(3pm)

=head1 CONSTRUCTOR

IWL::Accordion::Page->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(tag => 'h1');

    $self->__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<appendContent> (B<OBJECT>)

Appends the object to the page

Parameter: B<OBJECT> - the IWL::Object(3pm) to be appended

=cut

sub appendContent {
    my ($self, $object) = @_;

    $self->{__content}->appendChild($object);
    return $self;
}

=item B<prependContent> (B<OBJECT>)

Prepends the object to the page

Parameter: B<OBJECT> - the IWL::Object(3pm) to be prepended 

=cut

sub prependContent {
    my ($self, $object) = @_;

    $self->{__content}->prependChild($object);
    return $self;
}

=item B<setTitle> (B<TEXT>)

Sets the text of the page title 

Parameters: B<TEXT> - the text of the page title

=cut

sub setTitle {
    my ($self, $text) = @_;

	$self->{childNodes}[0]->setContent($text);
    return $self;
}

=item B<getTitle>

Returns the title of the page

=cut

sub getTitle {
	return shift->{childNodes}[0]->getContent;
}

=item B<setSelected> (B<BOOL>)

Sets whether the page is the currently selected page

Parameters: B<BOOL> - true if the page should be the currently selected one

=cut

sub setSelected {
    my ($self, $bool) = @_;

    $self->{__selected} = $bool ? 1 : 0;
    return $self;
}

=item B<isSelected>

Returns true if the page is the currently selected one

=cut

sub isSelected {
    return !(!shift->{__selected});
}

# Overrides
#
sub setId {
    my ($self, $id) = @_;

    $self->SUPER::setId($id . '_title');
    $self->{__content}->setId($id);

    return $self;
}

# Protected
#
sub _setupDefaultClass {
    my $self = shift;

    if ($self->{_accordion}) {
	$self->prependClass($self->{_defaultClass} . '_' 
	      . $self->{_accordion}{_options}{direction});
	$self->{__content}->prependClass('accordion_page_content_' 
	      . $self->{_accordion}{_options}{direction});
    }
    if ($self->isSelected) {
	$self->prependClass($self->{_defaultClass} . '_selected');
	$self->{__content}->prependClass('accordion_page_content_selected');
    }
    $self->prependClass($self->{_defaultClass});
    $self->{__content}->prependClass('accordion_page_content');
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $page = IWL::Container->new;

    $self->{_defaultClass} = 'accordion_page_title';
    $args{id} ||= randomize('accordion_page');

    $self->{__content} = $page;
    $self->{__selected} = 0;

	$self->appendChild(IWL::Text->new);
	$self->appendAfter($page);
    $self->_constructorArguments(%args);
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
