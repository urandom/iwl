#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Parser;

use strict;

use IWL::Text;
use IWL::Widget;
use IWL::Comment;
use base 'HTML::Parser';

=head1 NAME

IWL::Parser - an HTML parser

=head1 INHERITANCE

HTML::Parser -> IWL::Parser

=head1 DESCRIPTION

The IWL::Parser reads an html file, and creates an IWL structure of objects from it.

=head1 CONSTRUCTOR

IWL::Parser->new 

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new;

    # The current object
    $self->{_current} = undef;
    # The IWL Object that will be returned
    $self->{_object} = undef;

    return $self;
}

=head1 METHODS

=over 4

=item B<createObjectFromFile> (B<FILE>)

Creates an IWL Object from the given HTML file.

Parameters: B<FILE> - the HTML file to be parsed

Returns the IWL Object.

=cut

sub createObjectFromFile {
    my ($self, $file) = @_;

    $self->parse_file($file);
    return $self->{_object};
}

=item B<createObject> (B<TEXT>)

Creates an IWL Object from the given HTML text.

Parameters: B<TEXT> - the HTML text to be parsed

Returns the IWL Object.

=cut

sub createObject {
    my ($self, $text) = @_;

    $self->parse($text);
    return $self->{_object};
}

# HTML::Parser callbacks
sub text {
    my ($self, $text) = @_;
    my $obj = IWL::Text->new($text);
    return $self->{_current}->appendChild($obj);
}

sub declaration {
    my ($self, $decl) = @_;
    return $self->{__decl} = $decl;
}

sub comment {
    my ($self, $comment) = @_;
    my $obj = IWL::Comment->new($comment);

    $self->commentParser(\$obj, $comment);
    return $self->{_current}->appendChild($obj);
}

sub start {
    my ($self, $tag, $attr, $attrseq, $origtext) = @_;
    # $attr is reference to a HASH, $attrseq is reference to an ARRAY
    my $obj = IWL::Widget->new;
    $obj->{_tag} = $tag;
    $obj->{_noChildren} = 0;
    if ($self->{__decl}) {
	$obj->{_declaration} = $self->{__decl};
	$self->{__decl} = undef;
    }
    foreach my $key (keys %$attr) {
	next if $key eq '/';
	if ($attr->{$key} =~ /<!--(.+?)-->/) {
	    $self->commentParser(\$obj, $1, $key);
	    next;
	}
	if ($key eq 'style') {
	    my $val = $attr->{$key};
	    $val =~ s/\s//g;
	    my %style = map {split /:/} split(/;/, $val);
	    $obj->setStyle(%style);
	} elsif ($key =~ /^on/) {
	    $obj->setAttribute($key, $attr->{$key}, 'none');
	} else {
	    $obj->setAttribute($key, $attr->{$key});
	}
    }
    if ($origtext =~ /\/>$/) {
	$obj->{_noChildren} = 1;
    }
    if ($self->{_current}) {
	$self->{_current}->appendChild($obj);
	$self->{_current} = $obj unless $obj->{_noChildren} == 1;
    } else {
	$self->{_current} = $obj unless $obj->{_noChildren} == 1;;
    }

    $self->{_object} = $obj if !$self->{_object};
    return $self;
}

sub end {
    my ($self, $tag, $origtext) = @_;
    my $current = $self->{_current};
    return unless $tag eq $current->{_tag};
    if ($current->{parentNode}) {
	$self->{_current} = $current->{parentNode};
    }
    return $self;
}

# IWL::Parser specific callbacks
sub commentParser {
    my ($self, $objref, $comment, $attr) = @_;
    # $objref - the referebce to the iwl comment, 
    # $comment - the comment text,
    # $attr - the attribute where the comment was found, if it wasn't a comment
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
