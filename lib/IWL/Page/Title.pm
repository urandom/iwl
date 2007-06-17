#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Page::Title;

use strict;

use base qw(IWL::Widget);

use IWL::Text;

=head1 NAME

IWL::Title - the <title> markup

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Page::Title

=head1 DESCRIPTION

Title adds a title to the page. It should not be used by itself, but through B<IWL::Page>;

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->{_tag} = "title";

    return $self;
}

=head1 METHODS

=over 4

=item B<setTitle> (B<TEXT>)

Sets the title text

Parameters: B<TEXT> - the text

=cut

sub setTitle {
    my ($self, $text) = @_;

    my $title = IWL::Text->new($text);
    return $self->setChild($title);
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
