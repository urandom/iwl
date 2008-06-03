#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Script;

use strict;

use base qw(IWL::Object);

use IWL::Text;
use IWL::Config qw(%IWLConfig);

=head1 NAME

IWL::Script - A script object.

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Script>

=head1 DESCRIPTION

The script object provides the B<E<lt>script type="text/javascipt"E<gt>> html markup, with all it's attributes.

=head1 CONSTRUCTOR

IWL::Script->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<E<lt>scriptE<gt>> markup would have.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);

    $self->{_tag} = "script";
    $self->{__scripts} = [];
    $self->setAttribute(type => 'text/javascript');
    $self->setAttribute($_ => $args{$_}) foreach (keys %args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setSrc> (B<SOURCE>)

Sets a "src='B<SOURCE>'" attribute to B<<script>>.

Parameter: B<SOURCE> - a URL to a javascript file, or an array reference of URIs, if both I<STATIC_URI_SCRIPT> and I<STATIC_UNION> options are set.

=cut

sub setSrc {
    my ($self, $source) = @_;
    require IWL::Static;

    if (ref $source eq 'ARRAY') {
        return $self->setAttribute(src =>
            IWL::Static->addMultipleRequest($source, 'text/javascript'),
            'uri'
        );
    } else {
        return $self->setAttribute(src => IWL::Static->addRequest($source), 'uri');
    }
}

=item B<getSrc>

Returns the source of the script

=cut

sub getSrc {
    return shift->getAttribute('src', 1);
}

=item B<appendScript> (B<STRING>)

Appends the strings as a child of the script object

Parameter: B<STRING> - the js string

=cut

sub appendScript {
    my ($self, $string) = @_;

    push @{$self->{__scripts}}, $string;
    return $self;
}

=item B<prependScript> (B<STRING>)

Prepends the strings as a child of the script object

Parameter: B<STRING> - the js string

=cut

sub prependScript {
    my ($self, $string) = @_;

    unshift @{$self->{__scripts}}, $string;
    return $self;
}

=item B<setScript> (B<STRING>)

Adds the strings as a child of the script object

Parameter: B<STRING> - the js string

=cut

sub setScript {
    my ($self, $string) = @_;

    $self->{__scripts} = [$string];
    return $self;
}

=item B<getScript>

Returns the script string from the object.
If the I<STRICT_LEVEL> value of L<IWL::Config> is greater than I<1>, the script will be encapsulated by B<E<lt>![CDATA[ ... ]]E<gt>>

=cut

sub getScript {
    my $self = shift;
    my $string = join ";\n", @{$self->{__scripts}};
    $string =~ s/;+/;/g;
    $string .= ';' if $string && $string !~ /;\s*$/;

    return $string
      ? $IWLConfig{STRICT_LEVEL} > 1
        ? "\n//<![CDATA[\n" . $string . "\n//]]>"
        : $string
      : '';
}

# Protected
#
sub _realize {
    my $self = shift;

    $self->SUPER::_realize;
    $self->appendChild(IWL::Text->new($self->getScript))
        unless $self->hasAttribute('src');
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
