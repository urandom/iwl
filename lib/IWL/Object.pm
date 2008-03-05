#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Object;

use strict;

use base 'IWL::Error';

use constant JSON_HEADER => "Content-type: application/json\nX-IWL: 1\n\n";
use constant HTML_HEADER => "Content-type: text/html; charset=utf-8\n\n";
use constant TEXT_HEADER => "Content-type: text/plain\n\n";

use IWL::Response;
use IWL::Config qw(%IWLConfig);
use IWL::String qw(encodeURI escapeHTML escape);
use IWL::JSON qw(toJSON);

use Scalar::Util qw(weaken isweak blessed reftype);

# cloneCache: Used to detect looped networks and avoid infinite recursion.
# initializedJs: A hash to keep track of required javascript files
use vars qw(%cloneCache %initializedJs);

# The IWL::Response object
my $response;

=head1 NAME

IWL::Object - Base object module for IWL

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object>

=head1 DESCRIPTION

This is the base object module for IWL. Every other module will inherit from it.

=head1 CONSTRUCTOR

IWL::Object->new

IWL::Object->newMultiple (B<ARGS>, B<ARGS>, ...)

Returns an array of multiple objects.

Parameters: B<ARGS> - if only one argument is passed, and it is a number, it is used to create that many number of objects. If the first argument is a number, and is followed by other arguments, the first argument will create the number of objects, with the rest of the arguments passed to the constructor. Otherwise, if the arguments are a list of hash references, they will be used to create the objects.

=head1 PROPERTIES

=over 4

=item B<childNodes>

An array of child objects for the current object. Null if there are no children.

=item B<parentNode>

The parent for the current object. Null if it has no parent.

=back

=cut

sub new {
    my $class = shift;
    my $self  = bless {}, $class;

    $self->{childNodes} = [];
    $self->{parentNode} = undef;

    # Containers will have this set to 0, Objects with no children: 1
    $self->{_noChildren} = 0;

    # Set to 1 if the object should not be used unless it has children
    $self->{_removeEmpty} = 0;

    # Required javascript files
    $self->{_requiredJs} = [];

    # True if the object is realized
    $self->{_realized} = 0;

    # Object tag
    $self->{_tag} = '';

    # The initialization scripts
    $self->{_initScripts} = [];

    $self->{_tailObjects} = [];

    return $self;
}

sub newMultiple {
    my ($proto, @args) = @_;
    my @objects;
    if (scalar @args == 1 && !ref $args[0]) {
	foreach (1..$args[0]) {
	    my $object = $proto->new;
	    push @objects, $object;
	}
    } else {
        if ($args[0] =~ /^\d+$/) {
            my $number = shift @args;
            foreach (1 .. $number) {
                my $object = $proto->new(@args);
                push @objects, $object;
            }
        } else {
            foreach my $args (@args) {
                my $object = $proto->new(%$args);
                push @objects, $object;
            }
        }
    }
    return @objects;
}

=head1 METHODS

=over 4

=item B<firstChild>

Returns the first child of the object

=cut

sub firstChild {
    return shift->{childNodes}[0];
}

=item B<lastChild>

Returns the last child of the object

=cut

sub lastChild {
    my $children = shift->{childNodes};
    return $children->[$#$children];
}

=item B<nextChild> (B<CURRENT_CHILD>)

Obtains the next child of the object.
Parameter: B<CURRENT_CHILD> - its sibling
Returns the child object, or null if there is no next child.

=cut

sub nextChild {
    my $self    = shift;
    my $current = shift;
    my $next;

    return unless $current;
    for (my $i = 0; $i < @{$self->{childNodes}}; $i++) {
        if ($current == $self->{childNodes}->[$i]) {
            $next = $self->{childNodes}->[$i + 1];
            last;
        }
    }

    return $next;
}

=item B<prevChild> (B<CURRENT_CHILD>)

Obtains the previous child of the object.
Parameter: B<CURRENT_CHILD> - its sibling
Returns the child object, or null if there is no previous child.

=cut

sub prevChild {
    my $self    = shift;
    my $current = shift;
    my $prev;

    return unless $current;
    for (my $i = @{$self->{childNodes}} - 1; $i >= 0; $i--) {
        last if $i == 0;
        if ($current == $self->{childNodes}->[$i]) {
            $prev = $self->{childNodes}->[$i - 1];
            last;
        }
    }

    return $prev;
}

=item B<getChildren>

Returns a reference to the array of child objects

=cut

sub getChildren {
    return shift->{childNodes};
}

=item B<nextSibling>

Returns the next sibling of the current object.

=cut

sub nextSibling {
    my $self = shift;

    return $self->{parentNode}->nextChild($self) if $self->{parentNode};
}

=item B<prevSibling>

Returns the previous sibling of the current object.

=cut

sub prevSibling {
    my $self = shift;

    return $self->{parentNode}->prevChild($self) if $self->{parentNode};
}

=item B<getParent>

Returns the parent object of the current object

=cut

sub getParent {
    return shift->{parentNode};
}

=item B<appendChild> (B<OBJECT>)

Appends B<OBJECT>  as a child to the current object.

Parameter: B<OBJECT> - the object to be appended (can be an array of objects)

=cut

sub appendChild {
    my ($self, @objects) = @_;

    @objects = grep {$_ && $_ ne $self} @objects;
    return if !@objects;
    return if $self->{_noChildren};

    $_->{parentNode} = $self and weaken $_->{parentNode}
        foreach grep {UNIVERSAL::isa($_, 'IWL::Object')} @objects;

    push @{$self->{childNodes}}, @objects;

    return $self;
}

=item B<prependChild> (B<OBJECT>)

Appends B<OBJECT>  as the first child to the current object, and moves the rest afterward.

Parameter: B<OBJECT> - the object to be prepended (can be an array of objects)

=cut

sub prependChild {
    my ($self, @objects) = @_;

    @objects = grep {$_ && $_ ne $self} @objects;
    return if !@objects;
    return if $self->{_noChildren};

    $_->{parentNode} = $self and weaken $_->{parentNode}
        foreach grep {UNIVERSAL::isa($_, 'IWL::Object')} @objects;

    unshift @{$self->{childNodes}}, @objects;

    return $self;
}

=item B<setChild> (B<OBJECT>)

Sets B<OBJECT>  as the only child to the current object, replacing any existing children.

Parameter: B<OBJECT> - the object to be set (can be an array of objects)

=cut

sub setChild {
    my ($self, @objects) = @_;

    @objects = grep {$_ && $_ ne $self} @objects;
    return if !@objects;
    return if $self->{_noChildren};

    $_->{parentNode} = $self and weaken $_->{parentNode}
        foreach grep {UNIVERSAL::isa($_, 'IWL::Object')} @objects;

    $self->{childNodes} = [];
    push @{$self->{childNodes}}, @objects;

    return $self;
}

=item B<insertAfter> (B<REFERENCE>, B<OBJECT>)

Inserts B<OBJECT> after B<REFERENCE>.

Parameter: B<OBJECT> - the object to be inserted (can be an array of objects)

=cut

sub insertAfter {
    my ($self, $reference, @objects) = @_;

    @objects = grep {$_ && $_ ne $self} @objects;
    return if !@objects;
    return if $self->{_noChildren};

    $_->{parentNode} = $self and weaken $_->{parentNode}
        foreach grep {UNIVERSAL::isa($_, 'IWL::Object')} @objects;

    my $i;
    for ($i = 0; $i < @{$self->{childNodes}}; $i++) {
	if ($self->{childNodes}[$i] == $reference) {
	    last;
	}
    }
    splice @{$self->{childNodes}}, $i + 1, 0, @objects;

    return $self;
}

=item B<clone> (B<DEPTH>)

Clones itself and optionally, its children

Parameters: B<DEPTH> - The optional depth limit of the cloning

Note: Copied the implementation from Clone::PP(3pm). Weak pointers are discarded, and not cloned. This is done to ensure that objects, such as the parent node of an object, are not cloned.

=cut

sub clone {
    my ($self, $depth) = @_;

    # Optional depth limit: after a given number of levels, do shallow copy.
    return $self if (defined $depth and $depth -- < 1);

    # Maintain a shared cache during recursive calls, then clear it at the end.
    local %cloneCache = (undef => undef) unless exists $cloneCache{undef};

    return $cloneCache{$self} if exists $cloneCache{$self};

    # Non-reference values are copied shallowly
    my $ref_type = reftype $self or return $self;

    # Extract both the structure type and the class name of referent
    my $class_name = blessed $self;

    # Some objects would prefer to clone themselves
    return $cloneCache{$self} = $self->_IWLClone()
      if $class_name && $self->can('_IWLClone');

    # To make a copy:
    # - Prepare a reference to the same type of structure;
    # - Store it in the cache, to avoid looping it it refers to itself;
    # - Tie in to the same class as the original, if it was tied;
    # - Assign a value to the reference by cloning each item in the original;

    my $copy;
    if ($ref_type eq 'HASH') {
        $cloneCache{$self} = $copy = {};
        if (my $tied = tied(%$self)) {tie %$copy, ref $tied}
        foreach my $key (keys %$self) {
            if (ref $self->{$key}) {
                if (isweak $self->{$key}) {
                    $copy->{$key} = $cloneCache{$self->{$key}} || $self->{$key};
                    weaken $copy->{$key};
                } else {
                    $copy->{$key} = clone($self->{$key}, $depth);
                }
            } else {
                $copy->{$key} = $self->{$key};
            }
        }
    } elsif ($ref_type eq 'ARRAY') {
        $cloneCache{$self} = $copy = [];
        if (my $tied = tied(@$self)) {tie @$copy, ref $tied}
        foreach my $val (@$self) {
            if (ref $val) {
                if (isweak $val) {
                    push @$copy, ($cloneCache{$val} || $val);
                    weaken @$copy[$#$copy];
                } else {
                    push @$copy, clone($val, $depth);
                }
            } else {
                push @$copy, $val;
            }
        }
    } elsif ($ref_type eq 'REF' or $ref_type eq 'SCALAR') {
        $cloneCache{$self} = $copy = \(my $var = "");
        if (my $tied = tied($$self)) {tie $$copy, ref $tied}
        if (isweak $self) {
            $copy = $cloneCache{$self} || $self;
            weaken $copy;
        } else {
            $$copy = clone($$self, $depth);
        }
    } else {
        # Shallow copy anything else; this handles a reference to code, glob, regex
        $cloneCache{$self} = $copy = $self;
    }

    # - Bless it into the same class as the original, if it was blessed;
    # - If it has a post-cloning initialization method, call it.
    if ($class_name) {
        bless $copy, $class_name;
        $copy->_IWLCloneInit if $copy->can('_IWLCloneInit');
    }

    return $copy;
}

=item B<getContent>

Returns the markup for the current object and its children.

=cut

sub getContent {
    my $self    = shift;
    my $content = '';

    if (!$self->{_realized}) {
	$self->{_realized} = 1;
	$self->_realize;
        $self->__addInitScripts;
    }

    return '' if $self->bad;

    return ''
      if (!@{$self->{childNodes}} && ($self->{_removeEmpty})
	  || $self->{_ignore});

    my @header_scripts;
    foreach (@{$self->{_requiredJs}}) {
	next if exists $initializedJs{$_->[0]};
	if ($self->isa('IWL::Page::Head')) {
	    push @header_scripts, $_->[1];
	} else {
	    $content .= $_->[1]->getContent;
	}
	$initializedJs{$_->[0]} = 1;
    }

    $content .= "<!" . $self->{_declaration} . ">\n" if $self->{_declaration};
    $content .= "<" . $self->{_tag};

    foreach my $key (keys %{$self->{_attributes}}) {
        my $value = $self->{_attributes}{$key};
	unless (defined $value) {
	    $content .= " $key";
	    next;
	}
	if (defined $self->{_escapings}{$key} &&  $self->{_escapings}{$key} eq 'uri') {
	    $value = encodeURI($value);
	} elsif (defined $self->{_escapings}{$key} && $self->{_escapings}{$key} eq 'escape') {
	    $value = escape($value);
	} elsif (defined $self->{_escapings}{$key} && $self->{_escapings}{$key} eq 'none') {
	    # No need to do anything here
	} else {
	    $value = escapeHTML($value);
	}
        $content .= qq( $key="$value");
    }

    my $style = join '; ', map{$_ . ': ' . $self->{_style}{$_}} keys %{$self->{_style}};
    $content .= qq( style="$style") if $style;

    if ($self->{_noChildren}) {
        $content .= " />\n";
    } else {
        $content .= ">";
        foreach my $child (@{$self->{childNodes}}) {
            $content .= $child->getContent if $child;
        }
	$content .= $_->getContent foreach (@header_scripts);
        $content .= "</" . $self->{_tag} . ">\n";
    }

    $content .= $_->getContent foreach @{$self->{_tailObjects}};

    return $content;
}

=item B<print>

Prints the current object and all of its children.

L<Warning>: Deprecated. Please see IWL::Object::send(3pm)

=cut

sub print {
    my $self = shift;

    $self->getResponseObject->send(content => $self->getContent);
    return $self;
}

=item B<printHTML>

Prints the HTML content of current object and all of its children, along with an HTML header.

L<Warning>: Deprecated. Please see IWL::Object::send(3pm)

=cut

sub printHTML {
    my $self = shift;

    $self->getResponseObject->send(content => $self->getContent, header => IWL::Object::getHTMLHeader());
    return $self;
}

=item B<getObject>

Returns the object and its children as a new object, with a structure needed for JSON

=cut

sub getObject {
    my $self     = shift;
    my $json     = {};
    my $children = [];
    my $js       = [];
    my $objects  = [];
    my $scripts  = [];

    if (!$self->{_realized}) {
	$self->{_realized} = 1;
	$self->_realize;
        $self->__addInitScripts;
    }

    return {} if $self->bad;

    return
      if (!@{$self->{childNodes}} && ($self->{_removeEmpty})
	  || $self->{_ignore});

    foreach (@{$self->{_requiredJs}}) {
	next if exists $initializedJs{$_->[0]};
	if (UNIVERSAL::isa($self, 'IWL::Page::Head')) {
	    push @{$self->{_tailObjects}}, $_->[1];
	} else {
	    push @$scripts, $_->[1]->getObject;
	}
	$initializedJs{$_->[0]} = 1;
    }

    foreach my $child (@{$self->{childNodes}}) {
        push @$children, $child->getObject if $child;
    }

    push @$objects, $_->getObject foreach @{$self->{_tailObjects}};

    my $attributes = {};
    foreach my $key (keys %{$self->{_attributes}}) {
        my $value = $self->{_attributes}{$key};
	if (defined $self->{_escapings}{$key} && $self->{_escapings}{$key} eq 'uri') {
	    $value = encodeURI($value);
	} elsif (defined $self->{_escapings}{$key} && $self->{_escapings}{$key} eq 'escape') {
	    $value = escape($value);
	} elsif (defined $self->{_escapings}{$key} && $self->{_escapings}{$key} eq 'none') {
	    # No need to do anything here
	} else {
	    $value = escapeHTML($value);
	}
	$attributes->{$key} = $value;
    }

    $attributes->{style} = $self->{_style} if keys %{$self->{_style}};

    $json->{attributes} = $attributes if keys %$attributes;
    $json->{children} = $children if @$children;
    $json->{tag} = $self->{_tag} if $self->{_tag};
    $json->{text} = $self->{_textContent} if defined $self->{_textContent};
    $json->{tailObjects} = $objects if @$objects;
    $json->{scripts} = $scripts if @$scripts;

    return $json;
}

=item B<getJSON>

Returns a JSON object for the current object and its children.

If the html looks like this:
  <div attr1="1" attr2="2" style="display: none;">
    <child1 />
    <child2 attr3="3" />
  </div>

The corresponding JSON object will look like this:

{"div": {"attributes": {"attr1": 1, "attr2": 2, "style": {"display": "none"}}, "children": ["child1", "child2": {"attributes": {"attr3": 3}}]}}

=cut

sub getJSON {
    my $self = shift;
    my $json = toJSON($self->getObject);

    return $json;
}

=item B<printJSON>

Prints the JSON of current object and all of its children, along with a javascript header.

L<Warning>: Deprecated. Please see IWL::Object::send(3pm)

=cut

sub printJSON {
    my $self = shift;

    $self->getResponseObject->send(content => $self->getJSON, header => IWL::Object::getJSONHeader());
    return $self;
}

=item B<printJSONHeader>

Prints the JSON Header which is used by IWL

L<Warning>: Deprecated. Please see IWL::Object::send(3pm)

=cut

sub printJSONHeader {
    return print JSON_HEADER;
}

=item B<printHTMLHeader>

Prints the HTML Header which is used by IWL

L<Warning>: Deprecated. Please see IWL::Object::send(3pm)

=cut

sub printHTMLHeader {
    return print HTML_HEADER;
}

=item B<printTextHeader>

Prints the Text Header which is used by IWL

L<Warning>: Deprecated. Please see IWL::Object::send(3pm)

=cut

sub printTextHeader {
    return print TEXT_HEADER;
}

=item B<getJSONHeader>

Returns the JSON Header which is used by IWL

=cut

sub getJSONHeader {
    return {"Content-type" => "application/json", "X-IWL" => "1"};
}

=item B<getHTMLHeader>

Returns the HTML Header which is used by IWL

=cut

sub getHTMLHeader {
    return {"Content-type" => "text/html; charset=utf-8"};
}

=item B<getTextHeader>

Returns the Text Header which is used by IWL

=cut

sub getTextHeader {
    return {"Content-type" => "text/plain"};
}

=item B<setAttribute> (B<ATTR>, B<VALUE>, B<ESCAPING>)

Appends an attribute to the opening tag.  The value gets automatically
URI escaped.  The function fails and returns false on an attempt to
set an illegal attribute.  Illegal attributes are attributes that contain
non US-ASCII characters or violate the XML specification.

If STRICT_LEVEL in iwl.conf is set to
a value greater than 1, an exception is thrown in case of illlegal
attributes.

Use B<setStyle> for setting the style attribute

Parameter:
  ATTR - the attribute name to be appended
  VALUE - the value of the attribute
  ESCAPING - optional, sets the method of escaping the value
    - html - html entity escaping [default]
    - uri - uri escaping
    - escape - the string is escaped using IWL::String::escape(3pm)
    - none

=cut

sub setAttribute {
    my ($self, $attr, $value, $escaping) = @_;

    return unless $attr;
    return if $attr eq 'style';

    unless ($attr =~ /^[a-zA-Z_:][-.a-zA-Z0-9_:]*$/) {
        require Carp;

        my $safe_attr = $self->__safeErrorFormat($attr);
	if ($IWLConfig{STRICT_LEVEL} > 1) {
            Carp::croak("Attempt to set illegal attribute '$safe_attr'");
        } else {
            Carp::carp("Attempt to set illegal attribute '$safe_attr'");
        }
        return;
    }

    $self->{_attributes}{$attr} = $value;
    if (($escaping && $escaping eq 'none') || !$value) {
	$self->{_escapings}{$attr} = 'none';
    } elsif ($escaping && $escaping eq 'uri') {
	$self->{_escapings}{$attr} = 'uri';
    } elsif ($escaping && $escaping eq 'escape') {
	$self->{_escapings}{$attr} = 'escape';
    } else {
	delete $self->{_escapings}{$attr};
    }

    return $self;
}

=item B<setAttributes> (B<%ATTRS>, B<ESCAPING>)

setAttributes is a wrapper to setAttribute. It sets all the attributes in the provided hash

Parameters: B<%ATTRS> - a hash of attributes, B<ESCAPING> - optionally provide a method of escaping (see I<setAttribute>)

=cut

sub setAttributes {
    my ($self, %attrs, $escaping) = @_;

    foreach my $key (keys %attrs) {
        $self->setAttribute($key, $attrs{$key}, $escaping);
    }

    return $self;
}

=item B<getAttribute> (B<ATTR>, B<UNESCAPED>)

Returns the value of the given attribute. Use B<getStyle> for getting the style attribute

Parameters: B<ATTR> - the attribute name to be returned, B<UNESCAPED> - optional, true if the value should be returned unescaped

=cut

sub getAttribute {
    my ($self, $attr, $unescaped) = @_;

    return unless $attr;
    my $value = $self->{_attributes}{$attr};
    return unless defined $value;

    return if $attr eq 'style';
    return $self->{_attributes}{$attr} if $unescaped;

    if (defined $self->{_escapings}{$attr} && $self->{_escapings}{$attr} eq 'none') {
	return $value;
    } elsif (defined $self->{_escapings}{$attr} && $self->{_escapings}{$attr} eq 'escape') {
	$value = escape($value);
    } elsif (defined $self->{_escapings}{$attr} && $self->{_escapings}{$attr} eq 'uri') {
	return encodeURI($value);
    } else {
	return escapeHTML($value);
    }
}

=item B<hasAttribute> (B<ATTR>)

Returns true if attribute B<ATTR> exists, false otherwise.

=cut

sub hasAttribute {
    my ($self, $attr) = @_;

    return unless $attr;
    return if $attr eq 'style';

    return exists $self->{_attributes}->{$attr};
}

=item B<deleteAttribute> (B<ATTR>)

Deletes the given attribute

Parameters: ATTR - the attribute name to be deleted

=cut

sub deleteAttribute {
    my ($self, $attr) = @_;

    return unless $attr;
    delete $self->{_attributes}{$attr};
    delete $self->{_escapings}{$attr};

    return $self;
}

=item B<appendAfter> (B<OBJECT>)

Appends an object after the current object

Parameters: B<OBJECT> - the object to be appended

=cut

sub appendAfter {
    my ($self, @objects) = @_;

    push @{$self->{_tailObjects}}, @objects;
    return $self;
}

=item B<requiredJs> [B<URLS>]

Adds the list of urls (relative to JS_DIR) as required by the object

Parameters: B<URLS> - a list of required javascript files

=cut

sub requiredJs {
    my ($self, @urls) = @_;

    require IWL::Script;

    foreach my $url (@urls) {
	if ($url eq 'base.js') {
	    $self->requiredJs(
		'dist/prototype.js',
		'prototype_extensions.js',
		'dist/effects.js',
		'dist/controls.js',
		'scriptaculous_extensions.js');
	}

	my $script = IWL::Script->new;
	my $src    = $url ;
	$src       = $IWLConfig{JS_DIR} . '/' . $src
	    unless $url =~ m{^(?:(?:https?|ftp|file)://|/)};

	$script->setSrc($src);
	push @{$self->{_requiredJs}}, [$src => $script];
    }

    return $self;
}

=item B<cleanStateful>

Class method that initializes all state data of the library.  Stateful
data is for example the list of already included javascript helper files.
If multiple html pages are generated within one process context, this
data has to be cleared, so that new pages will start with fresh data.

You will also need to call this method, when using IWL inside of
Catalyst(3pm) when running the application with the built-in http
server that does not reload modules for each request.

This method is a class method!  You do not need to instantiate an object
in order to call it.

=cut

sub cleanStateful {
    %initializedJs = ();
}

=item B<getState>

Returns the current state of the form as an L<IWL::Stash> object.
The form state reflects the state of all of its children of
type L<IWL::Input>.

=cut

sub getState {
    my ($self) = @_;

    require IWL::Stash;
    my $state = IWL::Stash->new;

    $self->__iterateForm ($self, $state, 'extractState');

    $state->setDirty (0);

    return $state;
}

=item B<applyState> (B<STATE>)

Returns the current state of the form to B<STATE>, an L<IWL::Stash> object.
The form state reflects the state of all of its children of
type L<IWL::Input>.

=cut

sub applyState {
    my ($self, $state) = @_;

    $self->__iterateForm ($self, $state, 'applyState');

    return $self;
}

=item B<getResponseObject>

Returns the final response object, used by every L<IWL::Object>

=cut

sub getResponseObject {
    $response = IWL::Response->new unless $response;
    return $response;
}

=item B<send> (B<%ARGS>)

Serializes and sends the object using IWL::Response::send(3pm)

Parameters: %ARGS - a hash of arguments. The following keys are supported:

=over 8

=item I<type>

Serializes the object to the given type, and sends the corresponding header. The following types are supported:

=over 12

=item I<html>

Serializes the object to HTML and sends it with a text/html header

=item I<json>

Serializes the object to JSON and sends it with an application/json header

=item I<text>

Serializes the object to HTML and sends it with a text/plain header

=back

=item B<header>

A hash reference, representing an HTTP header, can be passed. It will extend the default header for those types.

=item B<static>

If true, an I<ETag>, generated using L<Digest::MD5>, will be added to the header of the response. If the I<ETag> matches the I<HTTP_IF_NONE_MATCH>, the response will also contain a I<Status> with a value of I<304>, and no actual content will be passed.

=item B<etag>

If provided, along with I<static>, it will use the values as an I<ETag> header, instead of using Digest::MD5. This is also useful, since no content needs to exist.

=back

=cut

sub send {
    my ($self, %args) = @_;
    my ($header, $content) = ref $args{header} eq 'HASH' ? $args{header} : {};

    if ($args{type} eq 'html') {
        $header = { %{IWL::Object::getHTMLHeader()}, %$header };
        $content = $self->getContent;
    } elsif ($args{type} eq 'json') {
        $header = { %{IWL::Object::getJSONHeader()}, %$header };
        $content = $self->getJSON;
    } elsif ($args{type} eq 'text') {
        $header = { %{IWL::Object::getTextHeader()}, %$header };
        $content = $self->getContent;
    } else {
        return;
    }

    if ($args{static}) {
        if ($args{etag}) {
            $header->{ETag} = $args{etag};
        } elsif (eval "require Digest::MD5") {
            $header->{ETag} = Digest::MD5::md5_hex($content);
        }
        if (exists $ENV{HTTP_IF_NONE_MATCH} && $ENV{HTTP_IF_NONE_MATCH} eq $header->{ETag}) {
            $header->{Status} = 304;
            $content = '';
        }
    }

    $self->getResponseObject->send(header => $header, content => $content);
    return $self;
}

=head1 PROTECTED METHODS

The following methods should only be used by classes that inherit
from B<IWL::Object>.

=cut

sub _appendAfter {
    my ($self, @objects) = @_;

    warn "_appendAfter is deprecated";
    unshift @{$self->{_tailObjects}}, @objects;
    return $self;
}

=item B<_appendInitScript> (B<SCRIPTS>)

Appends B<SCRIPTS> to the list of the object's initialization scripts

Parameters: B<SCRIPTS> - JavaScript code, which will be inserted into an L<IWL::Script> widget upon realization

=cut

sub _appendInitScript {
    my ($self, @scripts) = @_;

    push @{$self->{_initScripts}}, @scripts;
    return $self;
}

=item B<_realize>

Realizes the object. It is right before the object is serialized into HTML or JSON

=cut

sub _realize {
}

=item B<_findTopParent>

Finds the top-most parent of the object and returns it.

=cut

sub _findTopParent {
    my $self = shift;
    my $element = $self;

    do {
        return $element if $element->isa('IWL::Page::Body') || !$element->{parentNode};
        $element = $element->{parentNode};
    } while $element;
    return $element;
}

# Internal
#
# Convert control characters, so that error messages cannot be tainted
# in logs or on the console.
sub __safeErrorFormat {
    my (undef, $string) = @_;

    return '' unless defined $string;

    $string =~ s/([\000-\037])/'<' . unpack ('H2', $1) . '>'/eg;
}

sub __iterateForm {
    my ($self, $obj, $state, $method) = @_;

    if ($obj->isa ('IWL::Input') && !$obj->isa ('IWL::Entry')) {
	my $type = $obj->getAttribute ('type');
	return 1 if $type && 'submit' eq lc $type;
	return 1 if $type && 'image' eq lc $type;

	$obj->$method ($state);

	return $self;
    }

    my $children = $obj->{childNodes};
    foreach my $child (@$children) {
	$self->__iterateForm ($child, $state, $method);
    }

    return $self;
}

sub __addInitScripts {
    my $self = shift;
    if (@{$self->{_initScripts}}) {
        require IWL::Script;

        my $parent = $self->_findTopParent || $self;
        my $expr = join '; ', @{$self->{_initScripts}};

        if ($expr) {
            $parent->{_initScriptElement} = IWL::Script->new
              unless $parent->{_initScriptElement};
            $parent->{_initScriptElement}->appendScript($expr . ';');
        }
        if ($parent->{_initScriptElement} && !$parent->{_initScriptElement}{_added}) {
            unshift @{$parent->{_tailObjects}}, $parent->{_initScriptElement}
              if $parent->{_initScriptElement};
            $parent->{_initScriptElement}{_added} = 1;
            $parent->{_initScriptElement}->setAttribute('iwl:initScript');
        }
    }
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
