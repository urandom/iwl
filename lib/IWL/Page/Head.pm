#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Page::Head;

use strict;

use base qw(IWL::Object);

use IWL::Page::Meta;

=head1 NAME

IWL::Page::Head - the <head> markup

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Page::Head>

=head1 DESCRIPTION

Head is a specific object, that is only usable from Page, and should not be used otherwise.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(@_);

    $self->{_tag} = "head";

    return $self;
}

# Protected
#
sub _realize {
    my $self = shift;

    $self->SUPER::_realize;
    $self->appendChild($self->{_title}) if $self->{_title};
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
