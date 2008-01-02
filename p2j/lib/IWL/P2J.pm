#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::P2J;

use strict;

use B::Deparse;
use IWL::JSON;
use PPI::Document;
use Scalar::Util qw(blessed);

use vars qw($VERSION);

my $ignore_json = 0;

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
            $token->set_content('var')      if $token->content =~ /my|our|local/;
            $token->set_content('for')      if $token->content eq 'foreach';
            $token->set_content('else if')  if $token->content eq 'elsif';
            $token->set_content('function') if $token->content eq 'sub';
        }

        return '';
    });

    $self->__parseStatement($_) foreach $document->schildren;

    my $js = $document->content;
    $js =~ s/[ ]+/ /g;
    return $js;
}

sub __parseStatement {
    my ($self, $statement) = @_;
    my ($ref, $js) = (ref $statement, '');

    return $js unless $statement->isa('PPI::Statement');

    $self->__parseSimpleStatement($statement)
      if $ref eq 'PPI::Statement' || $ref eq 'PPI::Statement::Variable';
    $self->__parseCompoundStatement($statement)
      if $ref eq 'PPI::Statement::Compound';

    return;
}

sub __parseSimpleStatement {
    my ($self, $statement) = @_;
    my ($i, $assignment, $operator, $sigil) = (-1, '');
    foreach my $child ($statement->schildren) {
        ++$i;
        next if !$child->parent;
        if ($child->isa('PPI::Structure::List')) {
            my $symbols = $child->find('Token::Symbol');
            if ($symbols) {
                foreach (@$symbols) {
                    $sigil = $_->symbol_type;
                    $self->__parseToken($_);
                }
            }
            if ($assignment || $self->__previousIsMethod($child)) {
                if ($sigil eq '@') {
                    $child->{start}->set_content('[');
                    $child->{finish}->set_content(']');
                } elsif ($sigil eq '%') {
                    $child->{start}->set_content('{');
                    $child->{finish}->set_content('}');
                    my $operators = $child->find(sub {$_[1]->isa('PPI::Token::Operator') && $_[1] eq ','});
                    if ($operators) {
                        for (my $j = 0; $j < @$operators; $j += 2) {
                            $operators->[$j]->set_content(':');
                        }
                    }
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
            $child->previous_sibling->delete if $child->previous_sibling->isa('PPI::Token::Whitespace');
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
        } elsif ($child->isa('PPI::Token::Word') && $child->content ne 'var' && $child->snext_sibling->isa('PPI::Structure::List')) {
            # Functions
            my @composition = split /::/, $child->content;
            my $function    = pop @composition;
            my $package     = (join '::', @composition) || 'main';
            my $coderef;
            {
                no strict 'refs';
                $coderef = *{"${package}::${function}"}{CODE};
            }
            if ($coderef) {
                $child->set_content($self->__getFunctionValue($child, $coderef));
            } else {
                $child->set_content(join '.', @composition, $function);
            }
        } elsif ($child->isa('PPI::Token::Quote')
                 && $child->snext_sibling->isa('PPI::Token::Operator')
                 && $child->snext_sibling->content eq '->') {
            $child->set_content($self->__getExpressionValue($child, $child->string));
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

sub __parseCompoundStatement {
    my ($self, $statement) = @_;
    my ($i, $assignment, $operator, $sigil) = (-1, '');
    foreach my $child ($statement->schildren) {
        ++$i;
        next if !$child->parent;
        if ($child->isa('PPI::Token::Word') && {if => 1, unless => 1, while => 1, until => 1, foreach => 1, for => 1}->{$child->content}) {
            if ($child->content eq 'unless' || $child->content eq 'until') {
                my $list = $child->snext_sibling;
                $child->set_content('if') if $child->content eq 'unless';
                $child->set_content('while') if $child->content eq 'until';
                $list->start->set_content('(!(');
                $list->finish->set_content('))');
            }
        } elsif ($child->isa('PPI::Structure::Condition')) {
            my $symbols = $child->find('Token::Symbol');
            if ($symbols) {
                foreach (@$symbols) {
                    $sigil = $_->symbol_type;
                    $self->__parseToken($_);
                }
            }
        } elsif ($child->isa('PPI::Token::Magic')
              && $child->sprevious_sibling->isa('PPI::Token::Word')
              && $child->sprevious_sibling->content eq 'for') {
            $child->delete;
        } elsif ($child->isa('PPI::Structure::ForLoop')) {
            if ($child->schildren == 1) {
                my $s = ($child->children)[0];
                my $operator = $s->find_first('Token::Operator');
                my $elements = $s->find(
                    sub {
                        return 1 if $_[1]->isa('PPI::Token::Number');
                        $self->__parseToken($_[1]) and return 1 if ($_[1]->isa('PPI::Token::Symbol'));
                    }
                );
                my $content = PPI::Token->new;

                if ($operator && $operator->content eq '..') {
                    # Range
                    $content->set_content(
                        'var _ = ' . $elements->[0]->content . '; _ < ' . ($elements->[1]->content + 1) . '; ++_'
                    );
                    $_->delete foreach $s->children;
                    $s->add_element($content);
                } elsif ($operator && $operator->content eq ',') {
                    # Anonymous array
                    my $array = PPI::Token->new;
                    my $st = PPI::Statement->new;
                    $array->set_content(
                        'var _$ = [' . join(',', map {$_->content} @$elements) . '];'
                    );
                    $st->add_element($array);
                    $statement->insert_before($st);
                    $content->set_content(
                        'var i = 0, _ = _$[0]; i < _$.length; _ = _$[++i]'
                    );
                    $_->delete foreach $s->children;
                    $s->add_element($content);
                    $st = PPI::Statement->new;
                    $array = PPI::Token->new;
                    $array->set_content('delete _$;');
                    $st->add_element($array);
                    $statement->insert_after($st);
                }
            } else {
                $self->__parseStatement($_) foreach $child->schildren;
            }
        } elsif ($child->isa('PPI::Structure::Block')) {
            $self->__parseStatement($_) foreach $child->schildren;
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
              ? do {
                    my $value = $self->{__pad}{$token->content}{value};
                    if (ref $value eq 'REF' && blessed $$value) {
                        $self->__getExpressionValue($token, $$value);
                    } else {
                        toJSON($value)
                    }
                }
              : $name;
            $token->set_content($pad_value);
        }
    }
    return $self;
}

# Checks whether the element's previous sibling is a method/function
sub __previousIsMethod {
    my ($self, $element) = @_;
    return unless $element->sprevious_sibling->isa('PPI::Token::Word')
      && $element->sprevious_sibling->content ne 'var';
    return 1;
}

# Get the object expression ($example->method()[->method2()...], $$example{foo}{bar}, or Example->method())
sub __getExpressionValue {
    my ($self, $element, $value) = @_;
    my ($start, $ret, $sprev) = ($element->snext_sibling, $value, $element->sprevious_sibling);

    $sprev->delete if $sprev->isa('PPI::Token::Cast') && $sprev->content eq '$';
    while (1) {
        $sprev = $start->sprevious_sibling;
        $sprev->delete unless $sprev == $element;
        if ($start->isa('PPI::Token::Operator') && $start->content eq '->') {
            $start = $start->snext_sibling and next;
        } elsif ($start->isa('PPI::Token::Word') && $sprev->isa('PPI::Token::Operator')) {
            my $method = $start->content;
            my @args = $self->__getArguments($start->snext_sibling);
            $ret = $ret->$method(@args);
        } elsif ($start->isa('PPI::Structure::Subscript') && $start->start->content eq '{') {
            my $property = ($start->children)[0]->content;
            $property =~ s/^'// and $property =~ s/'$//;
            $ret = $ret->{$property};
        } elsif ($start->isa('PPI::Structure::Subscript') && $start->start->content eq '[') {
            my $property = ($start->children)[0]->content;
            $ret = $ret->[$property];
        } else {
            last;
        }
        $start = $start->snext_sibling;
    }
    return toJSON($ret);
}

# Returns a perl function value (foo() or Foo::bar())
sub __getFunctionValue {
    my ($self, $element, $coderef) = @_;
    my $list = $element->snext_sibling;

    return toJSON($coderef->($self->__getArguments($list)));
}

# Returns a list of arguments, which are to be passed to a function/method
sub __getArguments {
    my ($self, $list) = @_;
    return () unless $list->isa('PPI::Structure::List');
    my ($element, @args) = $list->children ? ((($list->children)[0])->children)[0] : ();
    $list->delete and return () unless $element;

    $ignore_json = 1;
    do {{
        next if $element->isa('PPI::Token::Operator');
        if ($element->isa('PPI::Token::Symbol')) {
            $self->__parseToken($element);
            push @args, $element->content;
        } elsif ($element->isa('PPI::Token::Quote')) {
            push @args, $element->string;
        } else {
            push @args, $element->content;
        }
    }} while ($element = $element->snext_sibling);
    $ignore_json = 0;

    $list->delete;
    return @args;
}

# Gets all 'outside' local lexical variables for the subref
sub __walker {
    my $self    = shift;
    my $cv      = B::svref_2object(shift);
    my $depth   = $cv->DEPTH ? $cv->DEPTH : 1;
    my $padlist = $cv->PADLIST;
    my %outside = map {$_ => 1} grep {defined $_} @{$cv->OUTSIDE->PADLIST->ARRAYelt(0)->object_2svref};
    my $names   = $padlist->ARRAYelt(0)->object_2svref;
    my $values  = [map {$_->object_2svref} $padlist->ARRAYelt($depth)->ARRAY];
    my $list    = {};
    for (my $i = 0; $i < @$names; ++$i) {
        next unless defined $names->[$i];
        next unless $outside{$names->[$i]};
        $list->{$names->[$i]} = {
            value => $values->[$i],
            type => ref $padlist->ARRAYelt($depth)->ARRAYelt($i),
        };
    }
    return $list;
}

# Local toJSON
sub toJSON {
    my $data = shift;
    return IWL::JSON::toJSON($data) unless $ignore_json;
    my $ref = ref $data;
    if ($ref eq 'SCALAR' || $ref eq 'REF') {
        $data = $$data;
    }
    return $data;
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
