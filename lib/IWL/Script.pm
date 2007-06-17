#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Script;

use strict;

use base qw(IWL::Object);

use IWL::Text;

=head1 NAME

IWL::Script - A script object.

=head1 INHERITANCE

IWL::Object -> IWL::Script

=head1 DESCRIPTION

The script object provides the B<<script type="text/javascipt">> html markup, with all it's attributes.

=head1 CONSTRUCTOR

IWL::Script->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<<script>> markup would have.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->{_tag} = "script";
    $self->setAttribute(type => 'text/javascript');
    $self->setAttribute($_ => $args{$_}) foreach (keys %args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setSrc> (B<SOURCE>)

Sets a "src='B<SOURCE>'" attribute to B<<script>>.

Parameter: B<SOURCE> - the js source

=cut

sub setSrc {
    my ($self, $source) = @_;

    return $self->setAttribute(src => $source, 'uri');
}

=item B<appendScript> (B<STRING>)

Appends the strings as a child of the script object

Parameter: B<STRING> - the js string

=cut

sub appendScript {
    my ($self, $string) = @_;

    $string =~ s/(?<!;)\s*$/;/;
    return $self->setScript($self->getScript() . $string);
}

=item B<prependScript> (B<STRING>)

Prepends the strings as a child of the script object

Parameter: B<STRING> - the js string

=cut

sub prependScript {
    my ($self, $string) = @_;

    $string =~ s/(?<!;)\s*$/;/;
    return $self->setScript($string . $self->getScript());
}

=item B<setScript> (B<STRING>)

Adds the strings as a child of the script object

Parameter: B<STRING> - the js string

=cut

sub setScript {
    my ($self, $string) = @_;

    $string =~ s/(?<!;)\s*$/;/;
    my $text = IWL::Text->new($string);
    return $self->setChild($text);
}

=item B<getScript>

Returns the script string from the object

=cut

sub getScript {
    my $self = shift;
    my $content = '';

    foreach my $child (@{$self->{childNodes}}) {
	$content .= $child->getContent;
    }

    return $content;
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
