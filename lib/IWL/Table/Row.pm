#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Table::Row;

use strict;

use base 'IWL::Widget';

use IWL::Table::Cell;
use IWL::String qw(randomize);

=head1 NAME

IWL::Table::Row - a row widget

=head1 INHERITANCE

L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Table::Row>

=head1 DESCRIPTION

The Row widget provides a row for IWL::Table.

=head1 CONSTRUCTOR

IWL::Table::Row->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<<tr>> markup would have.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $id = $args{id};
    delete @args{qw(id)};

    my $self = $class->SUPER::new(%args);

    $self->{_tag}  = "tr";
    $self->{_defaultClass} = 'table_row';
    unless ($args{id}) {
	$id ||= randomize($self->{_defaultClass});
	$self->setId($id);
    }

    return $self;
}

=head1 METHODS

=over 4

=item B<appendHeaderCell> (B<OBJECT>, [B<ATTRS>])

Adds a header cell to the row, with B<OBJECT> as it's content.

Parameters: B<OBJECT> - the IWL::Object(3pm), B<ATTRS> - hash of attributes for the cell

=cut

sub appendHeaderCell {
    my ($self, $object, %attrs) = @_;

    return $self->__append_cell($object, \%attrs, 'header');
}

=item B<prependHeaderCell> (B<OBJECT>, [B<ATTRS>])

Prepends a header cell to the row, with B<OBJECT> as it's content.

Parameters: B<OBJECT> - the IWL::Object(3pm), B<ATTRS> - hash of attributes for the cell

=cut

sub prependHeaderCell {
    my ($self, $object, %attrs) = @_;

    return $self->__prepend_cell($object, \%attrs, 'header');
}

=item B<appendTextHeaderCell> (B<TEXT>, [B<ATTRS>])

Adds a header cell to the row, with B<TEXT> as it's text content.

Parameters: B<TEXT> - the text to fill the cell, B<ATTRS> - hash of attributes for the cell

=cut

sub appendTextHeaderCell {
    my ($self, $text, %attrs) = @_;

    return $self->appendHeaderCell(IWL::Text->new($text), %attrs);
}

=item B<prependTextHeaderCell> (B<TEXT>, [B<ATTRS>])

Prepends a header cell to the row, with B<TEXT> as it's text content.

Parameters: B<TEXT> - the text to fill the cell, B<ATTRS> - hash of attributes for the cell

=cut

sub prependTextHeaderCell {
    my ($self, $text, %attrs) = @_;

    return $self->prependHeaderCell(IWL::Text->new($text), %attrs);
}

=item B<appendCell> (B<OBJECT>, [B<ATTRS>])

Adds a regular cell to the row, with B<OBJECT> as it's content.

Parameters: B<OBJECT> - the IWL::Object(3pm), B<ATTRS> - hash of attributes for the cell

=cut

sub appendCell {
    my ($self, $object, %attrs) = @_;

    return $self->__append_cell($object, \%attrs);
}

=item B<prependCell> (B<OBJECT>, [B<ATTRS>])

Prepends a regular cell to the row, with B<OBJECT> as it's content.

Parameters: B<OBJECT> - the IWL::Object(3pm), B<ATTRS> - hash of attributes for the cell

=cut

sub prependCell {
    my ($self, $object, %attrs) = @_;

    return $self->__prepend_cell($object, \%attrs);
}

=item B<appendTextCell> (B<TEXT>, [B<ATTRS>])

Adds a regular cell to the row, with B<TEXT> as it's text content.

Parameters: B<TEXT> - the text to fill the cell, B<ATTRS> - hash of attributes for the cell

=cut

sub appendTextCell {
    my ($self, $text, %attrs) = @_;

    return $self->appendCell(IWL::Text->new($text), %attrs);
}

=item B<prependTextCell> (B<TEXT>, [B<ATTRS>])

Prepends a regular cell to the row, with B<TEXT> as it's text content.

Parameters: B<TEXT> - the text to fill the cell, B<ATTRS> - hash of attributes for the cell

=cut

sub prependTextCell {
    my ($self, $text, %attrs) = @_;

    return $self->prependCell(IWL::Text->new($text), %attrs);
}

# Internal
#
sub __append_cell {
    my ($self, $data, $attrs, $type) = @_;

    my $cell = $self->__create_cell($type, $attrs);;
    $cell->appendChild($data);
    $self->appendChild($cell);

    $cell->{_row}    = $self;
    $cell->{_colNum} = @{$self->{childNodes}} - 1;

    return $cell;
}

sub __prepend_cell {
    my ($self, $data, $attrs, $type) = @_;

    my $cell = $self->__create_cell($type, $attrs);;
    $cell->appendChild($data);
    $self->prependChild($cell);

    $cell->{_row} = $self;
    for (my $i = 0; $i < @{$self->{childNodes}}; ++$i) {
	$self->{childNodes}[$i]{_colNum} = $i;
    }

    return $cell;
}

sub __create_cell {
    my ($self, $type, $attrs) = @_;
    return IWL::Table::Cell->new(type => $type, %$attrs);
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
