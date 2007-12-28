#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::P2J;

use strict;

use B::Deparse;
use PPI::Document;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

IWL::P2J - a basic Perl to JavaScript converter

=head1 DESCRIPTION

IWL::P2J is a class, which provides methods for converting perl subroutines into javascript code. This is a VERY experimental module, whose goal is to provide a way for developers to use Perl code in IWL signal handlers.

=head1 CONSTRUCTOR

IWL::P2J->new

=cut

sub new {
    my ($proto) = @_;
    my $class = ref($proto) || $proto;
    my $self = bless {}, $class;

    $self->{__deparser} = B::Deparse->new("-sC", "-q");

    return $self;
}

=head1 METHODS

=over 4

=item B<convert> (B<SUBREF>)

Tries to convert a subroutine reference into JavaScript code

Parameters: B<SUBREF> - a subroutine reference

Returns the converted JavaScript code

=cut

sub convert {
    my ($self, $subref) = @_;
    return '' if !$subref;
    my @perl = split /\n/, $self->{__deparser}->coderef2text($subref);
    shift @perl, pop @perl;
    foreach (@perl) {
        $_ =~ s/\s+/ /g;
        $_ =~ s/^\s+//;
    }

    $self->{__pad} = $self->__walker($subref);
    return $self->__parser(join "", @perl);
}

# Internal
#
sub __parser {
    my ($self, $perl) = @_;
    return '' unless $perl;
    my $document = $self->{__currentDocument} = PPI::Document->new(\$perl);
    $document->prune('Token::Comment');
    $document->prune('Token::Pod');
    $document->prune('Statement::Package');
    $document->prune('Statement::Include');
    $document->prune('Statement::Null');
    $document->find(sub {
        my $token = $_[1];
        if ($token->isa('PPI::Token::Operator')) {
            $token->set_content('<')  if $token->content eq 'lt';
            $token->set_content('>')  if $token->content eq 'gt';
            $token->set_content('<=') if $token->content eq 'le';
            $token->set_content('>=') if $token->content eq 'ge';
            $token->set_content('==') if $token->content eq 'eq';
            $token->set_content('!=') if $token->content eq 'ne';
            $token->set_content('+')  if $token->content eq '.';
            $token->set_content('&&') if $token->content eq 'and';
            $token->set_content('||') if $token->content eq 'or';
            $token->set_content('!')  if $token->content eq 'not';
        } elsif ($token->isa('PPI::Token::Word')) {
            $token->set_content('var')     if $token->content =~ /my|our|local/;
            $token->set_content('for')     if $token->content eq 'foreach';
            $token->set_content('else if') if $token->content eq 'elsif';
        }

        return '';
    });

    $self->__parseStatement($_) foreach $document->children;

    my $js = $document->content;
    $js =~ s/[ ]+/ /g;
    return $js;
}

sub __parseStatement {
    my ($self, $statement) = @_;
    my $js = '';

    return $js unless $statement->isa('PPI::Statement');

    $self->__parseSimpleStatement($statement)
      if ref $statement eq 'PPI::Statement' || ref $statement eq 'PPI::Statement::Variable';

    return;
}

sub __parseSimpleStatement {
    my ($self, $statement) = @_;
    my ($i, $assignment, $operator, $sigil) = (-1, '');
    foreach my $child ($statement->children) {
        ++$i;
        next if $child->isa('PPI::Token::Whitespace');
        if ($child->isa('PPI::Structure::List')) {
            my $symbols = $child->find('Token::Symbol');
            if ($symbols) {
                foreach (@$symbols) {
                    $sigil = $_->symbol_type;
                    $self->__parseToken($_);
                }
            }
            if ($assignment) {
                if ($sigil eq '@') {
                    $child->{start}->set_content('[');
                    $child->{finish}->set_content(']');
                } elsif ($sigil eq '%') {
                    $child->{start}->set_content('{');
                    $child->{finish}->set_content('}');
                }
            } else {
                $child->{start}->set_content(' ');
                $child->{finish}->set_content(' ');
            }
        } elsif ($child->isa('PPI::Structure::Constructor')) {
            # Converts ',' to ':' for hashes
            if ($child->{start}->content eq '{') {
                my $operators = $child->find(sub {$_[1]->isa('PPI::Token::Operator') && $_[1] eq ','});
                for (my $j = 0; $j < @$operators; $j += 2) {
                    $operators->[$j]->set_content(':');
                }
            }
        } elsif ($child->isa('PPI::Token::Word') && {if => 1, unless => 1, while => 1, until => 1, foreach => 1, for => 1}->{$child->content}) {
            # Statement modifiers
            my $brace = PPI::Token->new;
            my @elements = ($child, $brace);
            my $next = $child;
            $child->previous_sibling->remove if $child->previous_sibling->isa('PPI::Token::Whitespace');
            while ($next = $next->next_sibling) {
                last if $next->isa('PPI::Token::Structure') && $next->content eq ';';
                push @elements, $next;
            }
            my $first = $child->parent->first_element;
            my $modifier = $child->content eq 'unless' || $child->content eq 'until' ? '!(' : '';
            $child->set_content('if') if $child->content eq 'unless';
            $child->set_content('while') if $child->content eq 'until';
            $brace->set_content(' (' . $modifier);
            $brace = PPI::Token->new;
            $modifier = ')' if $modifier;
            $brace->set_content($modifier . ') ');
            push @elements, $brace;
            $first->insert_before($_->remove) foreach @elements;
        } elsif ($child->isa('PPI::Token')) {
            if ($child->isa('PPI::Token::Operator')) {
                $operator = 1;
                $assignment = $child->content eq '=';
            } elsif ($child->isa('PPI::Token::Symbol')) {
                $sigil = $child->symbol_type;
            }
            $self->__parseToken($child);
        }
    }
}

sub __parseToken {
    my ($self, $token) = @_;
    if ($token->isa('PPI::Token::Symbol')) {
        my $assignment;
        my $snext = $token;
        while ($snext = $snext->snext_sibling) {
            if ($snext->isa('PPI::Token::Operator') && $snext->content eq '=') {
                $assignment = 1;
                last;
            }
        }
        my $sigil = $token->symbol_type;
        my $content = $token->content;
        my $name = substr $content, 1;
        if ($assignment) {
            $self->{__currentDocument}{__variables}{$sigil} = {$name => 1};
            $token->set_content($name);
        } else {
            my $pad_value = $self->{__pad}{$token->content}
              ? $self->{__pad}{$token->content}{string}
                ? '"' . $self->{__pad}{$token->content}{value} . '"'
                : $self->{__pad}{$token->content}{value}
              : $name;
            $token->set_content($pad_value);
        }
    }
}

sub __walker {
    my $self    = shift;
    my $cv      = B::svref_2object(shift);
    my $depth   = $cv->DEPTH ? $cv->DEPTH : 1;
    my $padlist = $cv->PADLIST;
    my %outside = map {$_ => 1} grep {defined $_} @{$cv->OUTSIDE->PADLIST->ARRAYelt(0)->object_2svref};
    my $names   = $padlist->ARRAYelt(0)->object_2svref;
    my $values  = $padlist->ARRAYelt($depth)->object_2svref;
    my $list    = {};
    for (my $i = 0; $i < @$names; ++$i) {
        next unless defined $names->[$i];
        next unless $outside{$names->[$i]};
        $list->{$names->[$i]} = {value => $values->[$i], string => $padlist->ARRAYelt($depth)->ARRAYelt($i)->isa('B::PV')};
    }
    return $list;
}

1;

=head1 AUTHOR

  Viktor Kojouharov

=head1 Website

L<http://code.google.com/p/iwl>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2007  Viktor Kojouharov. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
