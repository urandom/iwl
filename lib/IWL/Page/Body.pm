#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Page::Body;

use strict;

use base qw(IWL::Widget);

=head1 NAME

IWL::Body - the <body> markup

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Page::Body

=head1 DESCRIPTION

Body is a specific object, that is only usable from Page, and should not be used otherwise.

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
