#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Table;

use strict;

use base 'IWL::Widget';

use IWL::Table::Container;
use IWL::Text;
use IWL::String qw(randomize);

=head1 NAME

IWL::Table - a table widget

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Table

=head1 DESCRIPTION

The Table widget provides a container that holds rows and columns of data.

=head1 CONSTRUCTOR

IWL::Table->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<<table>> markup would have.
  spacing - the cellspacing attribute, defaults to 0
  padding - the cellpadding attribute, defaults to 0

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->{_tag} = "table";
    if ($args{spacing}) {
        $self->setAttribute(cellspacing => $args{spacing});
    } else {
        $self->setAttribute(cellspacing => 0);
    }
    if ($args{padding}) {
        $self->setAttribute(cellpadding => $args{padding});
    } else {
        $self->setAttribute(cellpadding => 0);
    }
    delete @args{qw(spacing padding)};
    $self->__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setCaption> (B<TEXT>)

Sets the caption of the table

Parameters: B<TEXT> - the text for the caption

=cut

sub setCaption {
    my ($self, $text) = @_;

    my $caption = IWL::Container->new;
    my $child   = IWL::Text->new($text);

    $caption->{_tag} = 'caption';
    $caption->appendChild($child);
    return $self->appendChild($caption);
}

=item B<setSummary> (B<TEXT>)

Sets the summary of the table

Parameters: B<TEXT> - the text for the summary

=cut

sub setSummary {
    my ($self, $text) = @_;

    return $self->setAttribute(summary => $text);
}

=item B<appendHeader> (B<ROW>)

Appends an array of rows to the header to the table. 

Parameters: B<ROW> - a row of IWL::Table::Rows

=cut

sub appendHeader {
    my ($self, $row) = @_;

    $self->{_header}->appendChild($row);
    if ($row->isa("IWL::Table::Row") || $row->isa("IWL::Tree::Row")) {
        $row->setClass($self->{_defaultClass} . "_header_row");
        $row->setId($self->getId
              . "_header_row_"
              . (@{$self->{_header}{childNodes}} - 1))
          if $self->getId && !$row->getId;
    }

    return $self;
}

=item B<appendBody> (B<ROW>)

Appends an array of rows to the body to the table. 

Parameters: B<ROW> - a row of IWL::Table::Rows

=cut

sub appendBody {
    my ($self, $row) = @_;

    $self->{_body}->appendChild($row);

    if ($row->isa("IWL::Table::Row")) {
        unless ($row->{_defaultClass}) {
            if ($self->{__alternate}) {
                if (@{$self->{_body}{childNodes}} % 2) {
                    $row->setClass($self->{_defaultClass} . "_body_row");
                } else {
                    $row->setClass($self->{_defaultClass} . "_body_row_alt");
                }
            } else {
                $row->setClass($self->{_defaultClass} . "_body_row");
            }
        }
        $row->setId(
            $self->getId . "_body_row_" . (@{$self->{_body}{childNodes}} - 1))
          if $self->getId && !$row->getId;
    }

    return $self;
}

=item B<appendFooter> (B<ROW>)

Appends an array of rows to the footer to the table. 

Parameters: B<ROW> - a row of IWL::Table::Rows

=cut

sub appendFooter {
    my ($self, $row) = @_;

    $self->{_footer}->appendChild($row);
    if ($row->isa("IWL::Table::Row") || $row->isa("IWL::Tree::Row")) {
	$row->setClass($self->{_defaultClass} . "_footer_row");
        $row->setId($self->getId
              . "_footer_row_"
              . (@{$self->{_footer}{childNodes}} - 1))
          if $self->getId && !$row->getId;
    }

    return $self;
}

=item B<setHeaderStyle> (B<STYLE>)

Sets the style of the header

Parameters: B<STYLE> - the given style, in hash format

=cut

sub setHeaderStyle {
    my ($self, %style) = @_;

    $self->{_header}->setStyle(%style);
    return $self;
}

=item B<setBodyStyle> (B<STYLE>)

Sets the style of the body

Parameters: B<STYLE> - the given style, in hash format

=cut

sub setBodyStyle {
    my ($self, %style) = @_;

    $self->{_body}->setStyle(%style);
    return $self;
}

=item B<setFooterStyle> (B<STYLE>)

Sets the style of the footer

Parameters: B<STYLE> - the given style, in hash format

=cut

sub setFooterStyle {
    my ($self, %style) = @_;

    $self->{_footer}->setStyle(%style);
    return $self;
}

=item B<setAlternate> (B<BOOL>)

Sets whether the rows of the table will alternate in class

Parameters: B<BOOL> - true if the rows should alternate

=cut

sub setAlternate {
    my ($self, $bool) = @_;

    if ($bool) {
	$self->{__alternate} = 1;
    } else {
	$self->{__alternate} = 0;
    }
    return $self;
}

=item B<isAlternating>

Returns whether the rows of the table will alternate

=cut

sub isAlternating {
    return shift->{__alternate};
}

# Overrides
#
sub setId {
    my ($self, $id) = @_;
    $self->SUPER::setId($id);
    $self->{_header}->setId($id . '_header') if ($self->{_header});
    $self->{_body}->setId($id . '_body')     if ($self->{_body});
    $self->{_footer}->setId($id . '_footer') if ($self->{_footer});

    return $self;
}

# Protected
#
sub _setupDefaultClass {
    my ($self) = @_;

    $self->prependClass($self->{_defaultClass});
    $self->{_header}->prependClass($self->{_defaultClass} . '_header');
    $self->{_footer}->prependClass($self->{_defaultClass} . '_body');
    $self->{_body}->prependClass($self->{_defaultClass} . '_footer');
}

# Internal
#
sub __init {
    my ($self, %args) = @_;

    $self->{_defaultClass} = 'table';
    $args{id} = randomize($self->{_defaultClass}) if !$args{id};
    my $class = $args{class} || $self->{_defaultClass};

    my $header = IWL::Table::Container->new(
        id    => "$args{id}_header",
        type  => 'header',
    );
    my $body = IWL::Table::Container->new(
        id    => "$args{id}_body",
    );
    my $footer = IWL::Table::Container->new(
        id    => "$args{id}_footer",
        type  => 'footer',
    );
    $body->{_removeEmpty} = 0;
    $self->_constructorArguments(%args);

    $self->{_header} = $header;
    $self->{_footer} = $footer;
    $self->{_body}   = $body;

    $self->appendChild($header);
    $self->appendChild($body);
    $self->appendChild($footer);

    $self->{__alternate} = 0;

    return $self;
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
