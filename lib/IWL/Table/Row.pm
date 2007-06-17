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

IWL::Object -> IWL::Widget -> IWL::Table::Row

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
    $id ||= randomize($self->{_defaultClass});
    $self->setId($id);

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

    return $self->__append_cell($object, %attrs, 'header');
}

=item B<appendCell> (B<OBJECT>, [B<ATTRS>])

Adds a regular cell to the row, with B<OBJECT> as it's content.

Parameters: B<OBJECT> - the IWL::Object(3pm), B<ATTRS> - hash of attributes for the cell

=cut

sub appendCell {
    my ($self, $object, %attrs) = @_;

    return $self->__append_cell($object, %attrs);
}

=item B<appendTextCell> (B<TEXT>, [B<ATTRS>])

Adds a regular cell to the row, with B<TEXT> as it's text content.

Parameters: B<TEXT> - the text to fill the cell, B<ATTRS> - hash of attributes for the cell

=cut

sub appendTextCell {
    my ($self, $text, %attrs) = @_;

    my $text_obj = IWL::Text->new($text);
    return $self->appendCell($text_obj, %attrs);
}

=item B<appendTextHeaderCell> (B<TEXT>, [B<ATTRS>])

Adds a header cell to the row, with B<TEXT> as it's text content.

Parameters: B<TEXT> - the text to fill the cell, B<ATTRS> - hash of attributes for the cell

=cut

sub appendTextHeaderCell {
    my ($self, $text, %attrs) = @_;

    my $text_obj = IWL::Text->new($text);
    $attrs{type} = 'header';
    return $self->appendCell($text_obj, %attrs);
}

# Internal
#
sub __append_cell {
    my ($self, $data, %attrs, $type) = @_;

    my $cell = IWL::Table::Cell->new(type => $type, %attrs);
    $cell->appendChild($data);
    $self->appendChild($cell);

    $cell->{_row}     = $self;
    $cell->{_colNum} = @{$self->{childNodes}} - 1;

    return $cell;
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
