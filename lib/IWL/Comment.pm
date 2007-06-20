#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Comment;

use strict;

use base 'IWL::Object';

=head1 NAME

IWL::Comment - a simple comment object

=head1 INHERITANCE

IWL::Object -> IWL::Text

=head1 DESCRIPTION

The Comment object produces html style comments

=head1 CONSTRUCTOR

IWL::Comment->new ([B<CONTENT>])

Where B<CONTENT> is an optional parameter that holds the contents of the comment object.

=cut

sub new {
    my ($proto, $content) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->{__content} = $content || "";
    $self->{__expr}    = '';
    $self->{__data}    = [];

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

    $self->{__content} .= ' ' . $content;

    return $self;
}

=item B<prependContent> (B<CONTENT>)

Prepends more text to the current context.

Parameter: B<CONTENT> - the text to be prepended

=cut

sub prependContent {
    my ($self, $content) = @_;

    $self->{__content} = $content . ' ' . $self->{__content};
}

=item B<setContent> (B<CONTENT>)

Sets B<CONTENT> as the current context.

Parameter: B<CONTENT> - the text to be set

=cut

sub setContent {
    my ($self, $content) = @_;

    $self->{__content} = $content;

    return $self;
}

=item B<setConditional> (B<EXPR>, B<CONTENT>)
  
Sets a conditional comment

Parameters: B<EXPR> - the conditional expression, without the [if ] (ex: lt IE 7 expands to [if lt IE 7]). The [endif] part will be placed automatically, B<CONTENT> - the comment content

=cut

sub setConditional {
    my ($self, $expr, $content) = @_;

    return $self->setContent("[if $expr]>$content<![endif]");
}

=item B<setConditionalData> (B<EXPR>, B<OBJECT>)
  
Sets a conditional comment with IWL objects

Parameters: B<EXPR> - the conditional expression, without the [if ] (ex: lt IE 7 expands to [if lt IE 7]). The [endif] part will be placed automatically, B<OBJECT> - IWL::Objects(3pm)

=cut

sub setConditionalData {
    my ($self, $expr, $data) = @_;

    $self->{__expr} = $expr;
    push @{$self->{__data}}, $data;
    return $self;
}

# Overrides
#
sub getContent {
    my $self = shift;

    if (scalar @{$self->{__data}}) {
	my $content = '<!--[if ' . $self->{__expr} . ']>';
	foreach my $data (@{$self->{__data}}) {
	    $content .= $data->getContent;
	}
	return $content .= "<![endif]-->\n";
    }
    return '<!-- ' . $self->{__content} . ' -->';
}

sub getObject {
    return {};
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
