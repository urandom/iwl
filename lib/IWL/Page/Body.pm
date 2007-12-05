#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Page::Body;

use strict;

use base qw(IWL::Widget);

=head1 NAME

IWL::Page::Body - the <body> markup

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Page::Body>

=head1 DESCRIPTION

Body is a specific object, that is only usable from Page, and should not be used otherwise.

=head1 SIGNALS

=over 4

=item B<load>

Fires when the user agent finishes loading all content within a document, including window, frames, objects and images

=item B<unload>

Fires when the user agent removes all content from a window or frame

=item B<beforeunload>

Fires before a document is unloaded

=item B<abort>

Fires when the page is stopped from loading before completely loaded

=item B<error>

Fires when the page cannot be loaded properly

=item B<resize>

Fires when a document view is resized

=item B<scroll>

Fires when a document view is scrolled

=back

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->{_tag} = "body";

    $self->{_signals} = {
        %{$self->{_signals}},
        load         => 1,
        unload       => 1,
        beforeunload => 1,
        abort        => 1,
        error        => 1,
        resize       => 1,
        scroll       => 1,
    };

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
