#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Environment;

use strict;

use base qw(IWL::Object);

=head1 NAME

IWL::Environment - An environment pseudo-object

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Environment>

=head1 DESCRIPTION

The IWL::Environment provides a pseudo-object, used to manage snippets of L<IWL::Object>s for a page. Its main purpose is managing shared resources, such as javascript files, whenever L<IWL::Page> is not used. Unlike L<IWL::Page>, L<IWL::Environment> does not produce any code, only the code of its children.

=head1 SINOPSYS

 use IWL;
 use IWL::Environment;

 my $env = IWL::Environment->new;

 # Building some IWL hierarchy
 my $container = IWL::Container->new;
 my $label = IWL::Label->new;
 my $button = IWL::Button->new;

 $label->setText('This button does not do anything');
 $button->setLabel('Click me!');
 $container->appendChild($label, $button);

 $env->appendChild($container);

 ...

 # Print out the env content,
 # as was as any shared resource (in this case, 'button.js')
 # The environment child stack is cleared
 $html .= $env->getContent;

 ...

 my $button2 = IWL::Button->newFromStock('IWL_STOCK_NEW');
 $env->appendChild($button2);

 ...

 # Print out only $button2, since the previous content was
 # already obtained. The shared resource, 'button.js',
 # is not printed again.
 $html .= $env->getContent;

 ...

 # Adding scripts as shared resources
 $env->requiredJs('/foo/bar.js');

 $html .= $env->getContent;

=head1 CONSTRUCTOR

IWL::Environment->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new;

    return $self;
}

=head1 METHODS

=over 4

=item B<getContent>

Returns the markup for the environment's children, and removes them from its stack.

=cut

sub getContent {
    my $self = shift;
    my $content = "";
    
    $self->_realize;

    foreach my $child (@{$self->{childNodes}}) {
        $content .= $child->getContent;
    }

    $self->{childNodes} = [];

    return $content;
}

=item B<getObject>

Returns the environment's children as a new object, with a structure needed for JSON

=cut

sub getObject {
    my $self = shift;
    my $object = $self->SUPER::getObject;

    delete $object->{$_} foreach qw(tag attributes text);
    $object->{environment} = 1;

    $self->{childNodes} = [];

    return $object;
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
