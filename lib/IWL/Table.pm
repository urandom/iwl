#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Table;

use strict;

use base 'IWL::Widget';

use IWL::Table::Container;
use IWL::Container;
use IWL::Text;
use IWL::String qw(randomize);

=head1 NAME

IWL::Table - a table widget

=head1 INHERITANCE

L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Table>

=head1 DESCRIPTION

The Table widget provides a container that holds rows and columns of data.

=head1 CONSTRUCTOR

IWL::Table->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<E<lt>tableE<gt>> markup would have.

=over 4

=item B<spacing>

The cellspacing attribute, defaults to 0

=item B<padding>

The cellpadding attribute, defaults to 0

=back

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
    $self->IWL::Table::__init(%args);

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

    $self->{__caption}->setChild(IWL::Text->new($text));
    return $self;
}

=item B<getCaption>

Gets the caption of the table

=cut

sub getCaption {
    my $self = shift;
    return '' unless $self->{__caption}{childNodes}[0];
    return $self->{__caption}{childNodes}[0]->getContent;
}

=item B<setSummary> (B<TEXT>)

Sets the summary of the table

Parameters: B<TEXT> - the text for the summary

=cut

sub setSummary {
    my ($self, $text) = @_;

    return $self->setAttribute(summary => $text);
}

=item B<getSummary>

Gets the summary of the table

=cut

sub getSummary {
    return shift->getAttribute('summary', 1);
}

=item B<appendHeader> (B<ROW>)

Appends an array of rows to the header to the table. 

Parameters: B<ROW> - a row of IWL::Table::Row(3pm)

=cut

sub appendHeader {
    my ($self, $row) = @_;

    $self->{_header}->appendChild($row);
    $row->appendClass($self->{_defaultClass} . "_header_row");

    return $self;
}

=item B<prependHeader> (B<ROW>)

Prepends an array of rows to the header to the table. 

Parameters: B<ROW> - a row of IWL::Table::Row(3pm)

=cut

sub prependHeader {
    my ($self, $row) = @_;

    $self->{_header}->prependChild($row);
    $row->appendClass($self->{_defaultClass} . "_header_row");

    return $self;
}

=item B<appendBody> (B<ROW>)

Appends an array of rows to the body to the table. 

Parameters: B<ROW> - a row of IWL::Table::Row(3pm)

=cut

sub appendBody {
    my ($self, $row) = @_;

    $self->{_body}->appendChild($row);

    if ($self->{__alternate}) {
	if (@{$self->{_body}{childNodes}} % 2) {
	    $row->appendClass($self->{_defaultClass} . "_body_row");
	} else {
	    $row->appendClass($self->{_defaultClass} . "_body_row_alt");
	}
    } else {
	$row->appendClass($self->{_defaultClass} . "_body_row");
    }

    return $self;
}

=item B<prependBody> (B<ROW>)

Prepends an array of rows to the body to the table. 

Parameters: B<ROW> - a row of IWL::Table::Row(3pm)

=cut

sub prependBody {
    my ($self, $row) = @_;

    $self->{_body}->prependChild($row);
    if ($self->{__alternate}) {
	for (my $i = 0; $i < @{$self->{_body}{childNodes}}; ++$i) {
	    my $r = $self->{_body}{childNodes}[$i];
	    $r->removeClass($self->{_defaultClass} . "_body_row");
	    $r->removeClass($self->{_defaultClass} . "_body_row_alt");
	    if ($i % 2) {
		$r->appendClass($self->{_defaultClass} . "_body_row_alt");
	    } else {
		$r->appendClass($self->{_defaultClass} . "_body_row");
	    }
	}
    } else {
	$row->appendClass($self->{_defaultClass} . "_body_row");
    }

    return $self;
}

=item B<appendFooter> (B<ROW>)

Appends an array of rows to the footer to the table. 

Parameters: B<ROW> - a row of IWL::Table::Row(3pm)

=cut

sub appendFooter {
    my ($self, $row) = @_;

    $self->{_footer}->appendChild($row);
    $row->appendClass($self->{_defaultClass} . "_footer_row");

    return $self;
}

=item B<prependFooter> (B<ROW>)

Prepends an array of rows to the footer to the table. 

Parameters: B<ROW> - a row of IWL::Table::Row(3pm)

=cut

sub prependFooter {
    my ($self, $row) = @_;

    $self->{_footer}->prependChild($row);
    $row->appendClass($self->{_defaultClass} . "_footer_row");

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

=item B<getHeaderStyle> ([B<ATTR>])

Gets the style of the header

Parameters: B<ATTR> - the attribute style property to be returned

=cut

sub getHeaderStyle {
    return shift->{_header}->getStyle(shift);
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

=item B<getBodyStyle> ([B<ATTR>])

Gets the style of the body

Parameters: B<ATTR> - the attribute style property to be returned

=cut

sub getBodyStyle {
    return shift->{_body}->getStyle(shift);
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

=item B<getFooterStyle> ([B<ATTR>])

Gets the style of the footer

Parameters: B<ATTR> - the attribute style property to be returned

=cut

sub getFooterStyle {
    return shift->{_footer}->getStyle(shift);
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
    return !(!shift->{__alternate});
}

# Overrides
#
sub setId {
    my ($self, $id) = @_;
    $self->SUPER::setId($id);
    $self->{_header}->setId($id . '_header');
    $self->{_body}->setId($id . '_body');
    $self->{_footer}->setId($id . '_footer');
    $self->{__caption}->setId($id . '_caption');

    return $self;
}

# Protected
#
sub _setupDefaultClass {
    my ($self) = @_;

    $self->prependClass($self->{_defaultClass});
    $self->{_header}->prependClass($self->{_defaultClass} . '_header');
    $self->{_footer}->prependClass($self->{_defaultClass} . '_footer');
    $self->{__caption}->prependClass($self->{_defaultClass} . '_caption');
    $self->{_body}->prependClass($self->{_defaultClass} . '_body');
}

# Internal
#
sub __init {
    my ($self, %args) = @_;

    $self->{_defaultClass} = 'table';
    $args{id} = randomize($self->{_defaultClass}) if !$args{id};

    my $header = IWL::Table::Container->new(type  => 'header');
    my $footer = IWL::Table::Container->new(type  => 'footer');
    my $body = IWL::Table::Container->new;
    my $caption = IWL::Container->new;

    $caption->{_removeEmpty} = 1;
    $caption->{_tag} = 'caption';
    $body->{_removeEmpty} = 0;

    $self->{_header}   = $header;
    $self->{_footer}   = $footer;
    $self->{_body}     = $body;
    $self->{__caption} = $caption;

    $self->prependChild($caption);
    $self->appendChild($header);
    $self->appendChild($body);
    $self->appendChild($footer);

    $self->{__alternate} = 0;
    $self->_constructorArguments(%args);

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
