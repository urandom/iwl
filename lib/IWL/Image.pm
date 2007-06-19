#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Image;

use strict;

use base 'IWL::Widget';

use IWL::Stock;

=head1 NAME

IWL::Image - an image widget

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Image

=head1 DESCRIPTION

The Image widget provides a wrapper for the B<<img>> markup tag.

=head1 CONSTRUCTOR

IWL::Image->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<<img>> markup would have.

IWL::Image->newFromStock (B<STOCK_ID>, [B<%ARGS>])

Where B<STOCK_ID> is the I<IWL::Stock> id.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);

    $self->{_signals} = {
        %{$self->{_signals}},
        load => 1,
    };
    $self->{_tag}  = "img";
    $self->{_noChildren} = 1;

    return $self;
}

sub newFromStock {
    my ($self, $stock_id, %args) = @_;
    my $image = IWL::Image->new(%args);

    $image->setFromStock($stock_id);

    return $image;
}

=head1 METHODS

=over 4

=item B<set> (B<SRC>)

Set sets the given source for the image widget.

Parameters: B<SRC> - the source for the image

=cut

sub set {
    my ($self, $src) = @_;

    return $self->setAttribute(src => $src, 'uri');
}

=item B<setAlt> (B<TEXT>)

Sets the alternative text of the image

Parameters: B<TEXT> - the text to be set

=cut

sub setAlt {
    my ($self, $text) = @_;

    return if !$text;

    return $self->setAttribute(alt => $text);
}

=item B<setFromStock> (B<STOCK_ID>, [B<SIZE>])

Sets the image from the stock id

Parameters: B<STOCK_ID> - the stock id, B<SIZE> - optional size ['small']

=cut

sub setFromStock {
    my ($self, $stock_id, $size) = @_;
    my $stock = IWL::Stock->new;
    my $alt   = $stock->getLabel($stock_id);
    my $image;

    if ($size) {
	$image = $stock->getSmallImage($stock_id) if ($size eq 'small');
    } else {
	$image = $stock->getSmallImage($stock_id);
    }

    $self->set($image);
    return $self->setAlt($alt);
}

=item B<getSrc>

Returns the URL of the image

=cut

sub getSrc {
    shift->getAttribute('src', 1);
}

=item B<getAlt>

Returns the alternative text of the image

=cut

sub getAlt {
    shift->getAttribute('alt', 1);
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
