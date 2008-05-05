#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::List;

use strict;

use base 'IWL::Container';

use IWL::String qw(randomize);
use IWL::List::Definition;

=head1 NAME

IWL::List - a list container

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container> -> L<IWL::List>

=head1 DESCRIPTION

A list widget, for ordered, unordered and definition lists

=head1 CONSTRUCTOR

IWL::List->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<type>

I<unordered> [default], I<ordered>, I<definition>

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

=item B<appendListItem> (B<OBJECT>, B<%ARGS>)

Appends an object as a list item to the current list

Parameters: B<OBJECT> - the L<IWL::Object>, B<%ARGS> - the hash attributes of the list item

=cut

sub appendListItem {
    my ($self, $object, %args) = @_;
    my $li = $self->__setup_li($object, %args);
    $self->appendChild($li);
    return $li;
}

=item B<prependListItem> (B<OBJECT>, B<%ARGS>)

Prepends an object as a list item to the current list

Parameters: B<OBJECT> - the L<IWL::Object>, B<%ARGS> - the hash attributes of the list item

=cut

sub prependListItem {
    my ($self, $object, %args) = @_;
    my $li = $self->__setup_li($object, %args);
    $self->prependChild($li);
    return $li;
}

=item B<appendListItemText> (B<TEXT>, B<%ARGS>)

Appends text as a list item to the current list

Parameters: B<TEXT> - the text, B<%ARGS> - the hash attributes of the list item

=cut

sub appendListItemText {
    my ($self, $text, %args) = @_;
    my $text_obj = IWL::Text->new($text);
    my $li = $self->__setup_li($text_obj, %args);
    $self->appendChild($li);
    return $li;
}

=item B<prependListItemText> (B<TEXT>, B<%ARGS>)

Prepends text as a list item to the current list

Parameters: B<TEXT> - the text, B<%ARGS> - the hash attributes of the list item

=cut

sub prependListItemText {
    my ($self, $text, %args) = @_;
    my $text_obj = IWL::Text->new($text);
    my $li = $self->__setup_li($text_obj, %args);
    $self->prependChild($li);
    return $li;
}

=item B<appendDef> (B<OBJECT>, B<TYPE>, B<%ARGS>)

Appends an object as a definition to the current list

Parameters: B<OBJECT> - the L<IWL::Object>, B<TYPE> - the type of the definition (key[default]/value), B<%ARGS> - the hash attributes of the list item

=cut

sub appendDef {
    my ($self, $object, $type, %args) = @_;
    my $li = $self->__setup_def($object, $type, %args);
    $self->appendChild($li);
    return $li;
}

=item B<prependDef> (B<OBJECT>, B<TYPE>, B<%ARGS>)

Prepends an object as a definition to the current list

Parameters: B<OBJECT> - the L<IWL::Object>, B<TYPE> - the type of the definition (key[default]/value), B<%ARGS> - the hash attributes of the list item

=cut

sub prependDef {
    my ($self, $object, $type, %args) = @_;
    my $li = $self->__setup_def($object, $type, %args);
    $self->prependChild($li);
    return $li;
}

=item B<appendDefText> (B<TEXT>, B<TYPE>, B<%ARGS>)

Appends text as a definition to the current list

Parameters: B<TEXT> - the text, B<TYPE> - the type of the definition (key[default]/value), B<%ARGS> - the hash attributes of the list item

=cut

sub appendDefText {
    my ($self, $text, $type, %args) = @_;
    my $text_obj = IWL::Text->new($text);
    my $li = $self->__setup_def($text_obj, $type, %args);
    $self->appendChild($li);
    return $li;
}

=item B<prependDefText> (B<TEXT>, B<TYPE>, B<%ARGS>)

Prepends text as a definition to the current list

Parameters: B<TEXT> - the text, B<TYPE> - the type of the definition (key[default]/value), B<%ARGS> - the hash attributes of the list item

=cut

sub prependDefText {
    my ($self, $text, $type, %args) = @_;
    my $text_obj = IWL::Text->new($text);
    my $li = $self->__setup_def($text_obj, $type, %args);
    $self->prependChild($li);
    return $li;
}

# Protected
#
sub _init {
    my ($self, %args) = @_;

    if (!$args{type} || $args{type} eq 'unordered') {
	$self->{_tag} = 'ul';
	$self->{_type} = 'unordered';
    } elsif ($args{type} eq 'ordered') {
	$self->{_tag} = 'ol';
	$self->{_type} = $args{type};
    } elsif ($args{type} eq 'definition') {
	$self->{_tag} = 'dl';
	$self->{_type} = $args{type};
    }
    delete $args{type};
    $self->{_defaultClass} = 'list_' . $self->{_type};
    $args{id} ||= randomize($self->{_defaultClass});
    $self->_constructorArguments(%args);
}

# Internal
#
sub __setup_li {
    my ($self, $data, %args) = @_;
    my $li = IWL::Widget->new;
    return if $self->{_type} eq 'definition';

    $li->{_defaultClass} = 'list_' . $self->{_type} . '_item';
    $li->{_tag} = 'li';
    $li->_constructorArguments(%args);
    $li->appendChild($data);

    return $li;
}

sub __setup_def {
    my ($self, $data, $type, %args) = @_;
    return unless $self->{_type} eq 'definition';
    $type = 'key' if !$type || $type ne 'value';
    my $li = IWL::List::Definition->new(type => $type, %args);

    $li->{_defaultClass} = 'list_' . $self->{_type} . '_' . $type;
    $li->appendChild($data);

    return $li;
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
