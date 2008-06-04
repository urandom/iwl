#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Label;

use strict;

use base qw(IWL::Widget);

use IWL::Break;
use IWL::Container;
use IWL::String qw(randomize);

use constant JUSTIFY => {
    left    => 1,
    right   => 1,
    center  => 1,
    justify => 1,
};

use constant TYPE => {
    em      => 1,
    pre     => 1,
    strong  => 1,
    cite    => 1,
    code    => 1,
    dfn     => 1,
    samp    => 1,
    kbd     => 1,
    var     => 1,
    abbr    => 1,
    acronym => 1,

    i	    => 1,
    b       => 1,
    u       => 1,

    h1      => 1,
    h2      => 1,
    h3      => 1,
    h4      => 1,
    h5      => 1,
    h6      => 1,
};

use IWL::Text;

=head1 NAME

IWL::Label - a label widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Label>

=head1 DESCRIPTION

The Label widget is a basic container widget specifically targeted for holding one text object.

=head1 CONSTRUCTOR

IWL::Label->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values:

=over 4

=item B<expand>

True if the label should expand to fill all the given area false if the label should be as long as the text inside it. (expand => false doesn't work with multi-line labels)

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $id = $args{id} || randomize("label");
    my $self = $class->SUPER::new();

    delete @args{qw(id)};
    if ($args{expand}) {
        $self->{_tag} = "p";
	$self->{__expand} = 1;
        delete $args{expand};
    } else {
        $self->{_tag} = "span";
	$self->{__expand} = 0;
	delete $args{expand};
    }
    $self->{_removeEmpty} = 1;
    $self->setId($id);
    $self->_constructorArguments(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<appendText> (B<TEXT>)

Appends the given text string to the label widget.

Parameters: TEXT - the text string

=cut

sub appendText {
    my ($self, $text) = @_;
    if (!defined $text) {
	$self->appendChild(IWL::Text->new);
	return $self;
    }

    my @elements = $self->__convert_newline($text);

    if (@elements) {
        $self->appendChild(@elements);
    } else {
        $self->appendChild(IWL::Text->new);
    }
    return $self;
}

=item B<appendTextType> (B<TEXT>, B<TYPE>, [B<ATTRS>])

Appends the given text string to the label widget, with type and style settings.

Parameters: B<TEXT> - the text string, B<TYPE> - the text type I<[em, strong, code, etc.]>, B<ATTRS> - an attributes hash.

Returns false if incorrect type was given.

=cut

sub appendTextType {
    my ($self, $text, $type, %args) = @_;

    return if !exists TYPE->{$type};

    my $obj = IWL::Container->new(%args);

    $obj->{_tag} = $type;
    if ($type eq 'pre') {
	my $text_obj = IWL::Text->new($text);
	$obj->appendChild($text_obj);
    } else {
	my @elements = $self->__convert_newline($text);
	$obj->appendChild(@elements);
    }
    return $self->appendChild($obj);
}

=item B<setText> (B<TEXT>)

Sets the given text string to the label widget, replacing the already existing text

Parameters: TEXT - the text string

=cut

sub setText {
    my ($self, $text) = @_;
    if (!defined $text) {
	$self->appendChild(IWL::Text->new);
	return $self;
    }

    my @elements = $self->__convert_newline($text);

    $self->{childNodes} = [];
    $self->appendChild(@elements) or return;
    return $self;
}

=item B<getText>

Rethrs the text of the label

=cut

sub getText {
    my ($self) = @_;
    my $text_label = '';
    foreach (@{$self->{childNodes}}) {
        if ($_->isa('IWL::Break')) {
            $text_label .= "\n";
        } else {
            $text_label .= $_->getContent if $_->isa('IWL::Text');
        }
    }

    return $text_label;
}

=item B<setJustify> (B<JUSTIFICATION>)

Sets the justification of the label.

Parameters: JUSTIFICATION - the justification type: left, right, center or justify

Returns false if incorrect justification was specified.

=cut

sub setJustify {
    my ($self, $justify) = @_;

    return if !exists JUSTIFY->{$justify};

    return $self->setStyle('text-align' => $justify);
}

# Convert \n to <br />
sub __convert_newline {
    my ($self, $text) = @_;

    my @elements;
    while ($text =~ s/(?=(?:.|\n))(.*)(\n)?//) {
	my $string = $1;
	if (defined $string) {
	    chomp $string;
	    my $obj = IWL::Text->new($string);
	    push @elements, $obj;
	}
	if ($2) {
	    my $obj = IWL::Break->new;
	    push @elements, $obj;
	}
    }

    return @elements;
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
