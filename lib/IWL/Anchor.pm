#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Anchor;

use strict;

use base 'IWL::Widget';

use IWL::String qw(randomize);

=head1 NAME

IWL::Anchor - an anchor widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Anchor>

=head1 DESCRIPTION

The anchor widget provides a way to associate links to other widgets.

=head1 CONSTRUCTOR

IWL::Anchor->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<E<lt>aE<gt>> markup would have.

=head1 SIGNALS

=over 4

=item B<focus>

Fires when the anchor receives focus either via the pointing device or by tab navigation

=item B<blur>

Fires when the anchor loses focus either via the pointing device or by tabbing navigation

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);

    $self->{_tag}  = "a";
    $self->{_signals} = {
        %{$self->{_signals}},
        focus  => 1,
        blur  => 1,
    };
    $self->{_defaultClass} = 'anchor';
    $self->setId(randomize($self->{_defaultClass})) unless $args{id};


    return $self;
}

=head1 METHODS

=over 4

=item B<setHref> (B<URL>)

Sets the href attribute for the anchor

Parameters: B<URL> - the url for the link

=cut

sub setHref {
    my ($self, $url) = @_;

    return $self->setAttribute(href => $url, 'uri');
}

=item B<getHref>

Gets the href attribute for the anchor

=cut

sub getHref {
    return shift->getAttribute('href', 1);
}

=item B<setTarget> (B<TARGET>)

Sets the target attribute for the anchor

Parameters: B<TARGET> - the target

=cut

sub setTarget {
    my ($self, $target) = @_;

    return $self->setAttribute(target => $target);
}

=item B<getTarget>

Gets the target attribute for the anchor

=cut

sub getTarget {
    return shift->getAttribute('target', 1);
}

=item B<setText> (B<TEXT>)

Sets the text inside the anchor

Parameters: B<TEXT> - the target

=cut

sub setText {
    my ($self, $text) = @_;

    my $text_obj = IWL::Text->new($text);
    return $self->appendChild($text_obj);
}

=item B<getText>

Rethrs the text of the anchor

=cut

sub getText {
    my ($self) = @_;
    my $text_label = '';
    foreach (@{$self->{childNodes}}) {
	$text_label .= $_->getContent if $_->isa('IWL::Text');
    }

    return $text_label;
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
