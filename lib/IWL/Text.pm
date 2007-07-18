#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Text;

use strict;

use base 'IWL::Object';

=head1 NAME

IWL::Text - a simple text object

=head1 INHERITANCE

L<IWL::Object> -> L<IWL::Text>

=head1 DESCRIPTION

The Text object can hold any text that doesn't have opening/closing tags. It doesn't have children.

=head1 CONSTRUCTOR

IWL::Text->new ([B<CONTENT>])

Where B<CONTENT> is an optional parameter that holds the contents of the text object.

=cut

sub new {
    my ($proto, $content) = @_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new();

    $self->{_textContent} = defined $content ? $content : "";

    return $self;
}

=head1 METHODS

=over 4

=item B<appendContent> (B<CONTENT>)

Appends more text to the current context.

Parameter: B<CONTENT> - the text to be appended

=cut

sub appendContent {
    my ($self, $content) = @_;
    return unless defined $content;

    $self->{_textContent} .= $content;

    return $self;
}

=item B<prependContent> (B<CONTENT>)

Prepends more text to the current context.

Parameter: B<CONTENT> - the text to be prepended

=cut

sub prependContent {
    my ($self, $content) = @_;
    return unless defined $content;

    $self->{_textContent} = $content . $self->{_textContent};
    return $self;
}

=item B<setContent> (B<CONTENT>)

Sets B<CONTENT> as the current context.

Parameter: B<CONTENT> - the text to be set

=cut

sub setContent {
    my ($self, $content) = @_;
    return unless defined $content;

    $self->{_textContent} = $content;

    return $self;
}

# Overrides
#
sub getContent {
    my $self = shift;

    return $self->{_textContent};
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
