#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::TextEditor;

use strict;

use IWL::JSON 'toJSON';

use base 'IWL::Textarea';

=head1 NAME

IWL::TextEditor - A rich text editor

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Input> -> L<IWL::Textarea> -> L<IWL::TextEditor>

=head1 DESCRIPTION

The text editor is a multi-line text entry for formatted text.

=head1 CONSTRUCTOR

IWL::TextEditor->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new;

    $self->__init(%args);
    return $self;
}

=head1 METHODS

=over 4

=item B<setPanel> (B<PANEL>)

Sets B<PANEL> as the panel for the editor

Parameters: B<PANEL> - a string ID for an existing widget, or an L<IWL::Widget>

=cut

sub setPanel {
    my ($self, $panel) = @_;
    if (defined $panel) {
        if (UNIVERSAL::isa($panel, 'IWL::Widget')) {
            $self->{__panelWidget} = $panel;
        } else {
            $self->{_options}{panel} = $panel;
        }
    } else {
        delete $self->{_options}{panel};
        delete $self->{__panelWidget};
    }

    return $self;
}

=item B<getPanel>

Returns the currently set panel, if any

=cut

sub getPanel {
    my $self = shift;
    return $self->{__panelWidget} ? $self->{__panelWidget} : $self->{_options}{panel};
}

# Protected
#
sub _realize {
    my $self = shift;
    my $id     = $self->getId;

    $self->SUPER::_realize;

    $self->{_options}{panel} = $self->{__panelWidget}->getId
        if $self->{__panelWidget};
    $self->{_options}{editors} = [map {$_->getId} @{$self->{__editorWidgets}}]
        if scalar @{$self->{__editorWidgets}};

    my $options = toJSON($self->{_options});
    $self->_appendInitScript("IWL.TextEditor.create('$id', $options);");
    $self->setStyle(visibility => 'hidden');
}


# Internal
#
sub __init {
    my ($self, %args) = @_;

    $self->{_options} = {editors => []};
    $self->{_options}{$_} = $args{$_}
        foreach grep {defined $args{$_}}
        qw(buttonList buttons fullPanel iconFiles iconList iconsPath);

    $self->setPanel($args{panel});

    $self->{__editorWidgets} = [];
    if (ref $args{editors} eq 'ARRAY') {
        foreach my $editor (@{$args{editors}}) {
            if (UNIVERSAL::isa($editor, 'IWL::Widget')) {
                push @{$self->{__editorWidgets}}, $editor;
            } else {
                push @{$self->{_options}{editors}}, $editor;
            }
        }
    }

    $self->{_defaultClass} = 'texteditor';

    $self->requiredJs('base.js', 'dist/nicEdit.js', 'texteditor.js');
    $self->_constructorArguments(%args);
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
