#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Stash;

use strict;

use Locale::TextDomain qw(org.bloka.iwl);
use IWL::String qw(encodeURI);

# Forward declarations.
sub newFromCGI;
sub newFromHash;
sub newFromHashReference;

sub new {
    my ($class, @args) = @_;

    if (@args) {
	if (ref $args[0] && 'HASH' eq ref $args[0]) {
	    return newFromHashReference ($class, $args[0]);
	} elsif (ref $args[0] && ($args[0] =~ /=/)) {
	    if ($args[0]->isa ('IWL::Stash')) {
		return clone ($class, $args[0]);
	    } elsif ($args[0]->isa ('CGI')) {
		return newFromCGI ($class, $args[0]);
	    }
	} elsif (0 == @args % 2) {
	    return newFromHash ($class, @args);
	}
    }

    my $state = {};
    bless {
	__state => $state,
    }, $class;
}

sub newFromCGI {
    my ($class, $cgi) = @_;

    my $info = {};

    my @keys = $cgi->param;
    foreach my $key (@keys) {
	$info->{$key} = [$cgi->param ($key)];
    }
    bless {
	__state => $info,
    }, $class;    
}

sub newFromHash {
    my ($class, %cgiform) = @_;

    return newFromHashReference ($class, \%cgiform);
}

sub newFromHashReference {
    my ($class, $cgiform) = @_;

    my $info = {};
    while (my ($key, $value) = each %$cgiform) {
	if (ref $value) {
	    $info->{$key} = [ @$value ];
	} else {
	    $info->{$key} = [ $value ];
	}
    }
    bless {
	__state => $info,
    }, $class;
}

sub clone {
    my ($class) = shift;
    my $old = shift;

    if (ref $class && $class->isa ('IWL::Stash')) {
	$old = $class unless $old;
	$class = ref $class;
    }

    my $oldstate = $old->{__state};
    my $new = {};
    my $newstate = $new->{__state} = {};

    while (my ($key, $list) = each %$oldstate) {
	$newstate->{$key} =  [ @$list ];
    }
    $new->{__dirty} = $old->{__dirty} if exists $old->{__dirty};

    bless $new, $class;
}

######################################################################
# Public methods.
######################################################################

sub getValues {
    my ($self, $key) = @_;

    if (exists $self->{__state}->{$key}) {
	return wantarray ? @{$self->{__state}->{$key}} :
	    $self->{__state}->{$key}->[0];
    }
    return;
}

sub setValues {
    my ($self, $key, $value, @tail) = @_;

    my $values;
    if (@tail) {
	$values = [ $value, @tail ];
    } elsif (ref $value && 'ARRAY' eq ref $value) {
	$values = $value;
    } else {
	$values = [ $value ];
    }

    $self->{__dirty} = $self->__compare ($key, $values)
	unless $self->{__dirty};
    $self->{__state}->{$key} = $values;
}

sub pushValues {
    my ($self, $key, $value, @tail) = @_;

    return $self->setValues ($key, $value, @tail)
	unless exists $self->{__state}->{$key};

    my @values;
    if (@tail) {
	@values = ($value, @tail);
    } elsif (ref $value) {
	@values = @$value;
    } else {
	@values = ($value);
    }
    $self->{__dirty} = 1;
    push @{$self->{__state}->{$key}}, @values;
}

sub deleteValues {
    my ($self, $key) = @_;
    my $state = $self->{__state};

    $self->{__dirty} = exists $state->{$key} unless $self->{__dirty};

    my $old_value = delete $state->{$key};

    return unless defined wantarray;
    return unless defined $old_value;

    return wantarray
	? @{$old_value}
    : $old_value->[0];
}

sub shiftValue {
    my ($self, $key) = @_;
    my $state = $self->{__state};

    return unless exists $state->{$key};
    
    my $value = shift @{$state->{$key}};
    delete $state->{$key} unless @{$state->{$key}};

    return $value;
}

sub popValue {
    my ($self, $key) = @_;
    my $state = $self->{__state};

    return unless exists $state->{$key};
    
    my $value = pop @{$state->{$key}};
    delete $state->{$key} unless @{$state->{$key}};

    return $value;
}

sub spliceValues {
    my ($self, $key_from, $offs_value, $len_value, @list_values) = @_;
    my $state = $self->{__state};

    return unless exists $state->{$key_from};

    return unless defined $offs_value;

    $self->{__dirty} = 1;
    if (defined ($len_value)) {
        if (scalar @list_values) {
            return splice ( @{$self->{__state}->{$key_from}}, $offs_value,
                            $len_value, @list_values );
        } else {
            return splice ( @{$self->{__state}->{$key_from}}, $offs_value,
                            $len_value );
        }
    } else {
        if (scalar @list_values) {
            return splice ( @{$self->{__state}->{$key_from}}, $offs_value,
                            $len_value, @list_values );
        } else {
            return splice ( @{$self->{__state}->{$key_from}}, $offs_value );
        }
    }
}

sub keys {
    keys %{shift->{__state}}
}

sub values {
    values %{shift->{__state}}
}

sub dump {
    my ($self) = @_;

    my $state = $self->{__state};
    my $retval = {};
    while (my ($key, $list) = each %$state) {
	$retval->{$key} = [@$list];
    }

    return $retval;
}

sub dirty {
    shift->{__dirty};
}

sub setDirty {
    my ($self, $dirty) = @_;

    if ($dirty) {
	return $self->{__dirty} = $dirty;
    } else {
	delete $self->{__dirty};
    }
    return $self;
}

sub mergeState {
    my ($self, $merger) = @_;

    foreach my $key ($merger->keys) {
	$self->pushValues ($key, $merger->getValues ($key));
    }

    return 1;
}

sub searchKey {
    my ($self, $key, $reg) = @_;
    eval {$reg = qr/$reg/i};
    return 0 if $@;

    if (exists $self->{__state}->{$key}) {
	foreach (@{$self->{__state}->{$key}}){
	    return 1 if /$reg/i;
	}
    }
    return 0;
}

sub searchAll {
    my ($self, $reg) = @_;

    # FIXME: The two lines below avoid Internal Server Errors
    # through invalid regex.
    # At present, no error message is displayed anywhere.
    eval {$reg = qr/$reg/i};
    return 0 if $@;

    foreach my $key (CORE::keys %{$self->{__state}}) {
	foreach (@{$self->{__state}->{$key}}){
	    return 1 if /$reg/;
	}
    }
    return 0;
}

sub existsKey {
    my ($self, $key) = @_;
    return exists $self->{__state}->{$key};
}

sub equals {
    my ($self, $other) = @_;

    return unless $self->_numKeys == $other->_numKeys;
    my @self_keys = sort $self->keys;
    my @other_keys = sort $other->keys;

    my $self_keys = join "\000", @self_keys;
    my $other_keys = join "\000", @other_keys;

    return if ($self_keys ne $other_keys);

    foreach (@self_keys) {
	return if $self->__compare ($_, [ $other->getValues ($_)]);
    }

    return $self;
}

sub toURIParams {
    my ($self) = @_;

    my @result;
    foreach my $key ($self->keys) {
	my @values = $self->getValues ($key);
	foreach my $value (@values) {
	    push @result, (encodeURI($key) . '=' 
			   . encodeURI($value));
	}
    }

    return join '&', @result;
}

sub toHiddenInputs {
    my ($self) = @_;

    require IWL::Container;
    require IWL::Hidden;
    
    my $container = IWL::Container->new;
    foreach my $key ($self->keys) {
	my @values = $self->getValues ($key);
	foreach my $value (@values) {
	    my $hidden = IWL::Hidden->new (name => $key,
					   value => $value);
	    $container->appendChild ($hidden);
	}
    }

    return $container;
}

######################################################################
# Protected methods.
######################################################################
sub _numKeys {
    scalar CORE::keys (%{shift->{__state}});
}

sub _setStateTo {
    my $self = shift;
    $self->{__state} = shift;
    return 1;
}

######################################################################
# Private methods.
######################################################################
# Return true if setting slot for KEY to VALUE changes the saved
# contents.
sub __compare {
    my ($self, $key, $new) = @_;

    my $state = $self->{__state};
    return 1 unless exists $state->{$key};
    my $old = $state->{$key};
    return 1 if (($old && !$new) || ($new && !$old) || (@$old != @$new));

    for (my $i = 0; $i < @$old; $i++) {
	return 1 if $old->[$i] ne $new->[$i];
    }
    return 0;
}

1;

=head1 NAME

IWL::Stash - Encapsulation of HTML form information

=head1 SYNOPSIS

  use IWL::Stash;

  my $state = IWL::Stash->new ({keywords => [ 'Movies',
                                              'Action'],
                                template => '911dvd'});

  my $keywords = $state->getValues ('keywords');

  $state->setValues (keywords => 'TV');

  $state->setValues (keywords => ['TV', 'Soap']);

  $state->setValues (keywords => ('TV', 'Soap'));

  $state->pushValues (keywords => 'Daily');

  $state->pushValues (keywords => ['Daily', 'Boring']);

  $state->pushValues (keywords => ('Daily', 'Boring'));

  # splice / pop
  $state->spliceValues (keywords => -1);

  # splice / push
  $state->spliceValues (keywords => (9, 0, ('new', 'values')));

  # splice / shift
  $state->spliceValues (keywords => (0, 1));

  # splice / unshift
  $state->spliceValues (keywords => (0, 0, ('new', 'values')));

  my $state_keys = $state->keys;

  my $dump = $state->dump;

=head1 DESCRIPTION

The B<IWL::Stash> class encapsulates the information that can be 
carried by an HTML form.

=head1 CONSTRUCTORS

=over 4

=item B<new [STATE]>

Create a new instance of the class.  It will be empty unless you provide
a B<STATE> argument that populates the IWL::Stash object with data.  The
B<STATE> argument is autodetected, and according on its type, the correct
constructor (either newFromCGI, newFromHash, newFromHashReference,
or clone) is called.

If you call the constructor with an unsupported B<STATE> argument, it
is silently ignored, and an empty state object is created instead.

=item B<newFromCGI CGIOBJECT>

Creates a new instance of the class, initialized with data retrieved
from B<CGIOBJECT>.  That argument should be a reference to a CGI(3pm)
object, and the data is extracted from that object with the method
param().

=item B<newFromHash FORMHASH>

Creates a new instance of the class from a hash where the values are
either scalars or array references (the latter for multi-valued input
fields).  Example:

  my $state = IWL::Stash->new (keywords => ['Movies',
                                            'Action'],
                               template => '911dvd');


Note that a reference to the B<FORMHASH> is used, and the array references 
possibly used as values are B<not>
dereferenced.  If that is an issue for you, copy your freshly created object
with the clone() constructor (see below).

=item B<newFromHashReference FORMHASH>

Just like newFromHash(), but the argument is a reference to a
hash as described above for newFromHash().

Example:

  my $state = IWL::Stash->new ({keywords => [ 'Movies',
                                              'Action' ],
                                template => '911dvd'});

Note all these references are B<not>
dereferenced.  If that is an issue for you, copy your freshly created object
with the clone() constructor (see below).

=item B<clone STATE>

Copy constructor that creates a deep copy of the STATE argument.

=back

=head1 PUBLIC METHODS

=over 4

=item B<getValues KEY>

Retrieves the corresponding values of input field B<KEY> or B<undef> if
there is no information stored under that key.

In scalar context only the first value is returned which might come in
handy if you are certain that there is only one associated value present.
In array context the complete list of associated values is returned.

=item B<setValues KEY, VALUE[, VALUES]>

This method can be used in various ways to set the information that
should be stored under B<KEY>.  If more than one value is passed to the
function (i. e. B<VALUES> is defined and is either a list or a scalar)
all values are stored in the object.  If B<VALUE> is a reference it is
treated as an array reference, dereferenced and the retrieved values get
stored.  If B<VALUE> is a scalar it will be stored as the sole value for
B<KEY>.

As the name already suggests the method will clobber any existing
information stored under B<KEY>

Will make the object dirty if the new content for B<KEY> differs from
the old content.

=item B<pushValues KEY, VALUE[, VALUES]>

Same as B<setValues> but the new values are appended to existing
information.  Note that you can safely call this method even if there
is nothing stored under B<KEY>.

=item B<deleteValues KEY>

Removes all values associated with the specified B<KEY>.

In array context, returns an array of all deleted values.
In scalar context, returns the first deleted value.

Will make the object dirty unless there has been no data associated with
B<KEY>.

=item B<shiftValue KEY>

Shifts the first value associated with B<KEY> off and returns it,
shortening the number of values associated with that key by 1.  It
returns false, if no value is associated with B<KEY>.

=item B<popValue KEY>

Pops the first value associated with B<KEY> off and returns it,
shortening the number of values associated with that key by 1.  It
returns false, if no value is associated with B<KEY>.

=item B<spliceValues KEY, OFFSET, LENGTH, VALUE[, VALUES]>

This method can be used in various ways to change the information stored
under B<KEY>.
Have a look at B<perldoc -f splice> for more information.

FIXME: Better documentation! At the moment, look at the source!

=item B<keys>

Returns the list of keys.

=item B<values>

Returns a list of array references, containing the values for all keys.

=item B<dump>

Returns a copy of the internal hash.

=item B<dirty>

Returns true if the object is dirty, i. e. its content has changed since
creation.

=item B<setDirty FLAG>

Sets resp. resets the object dirty state according to the boolean attribute
B<FLAG>.

=item B<mergeState MERGER>

"Merges" the state B<MERGER> into the state.  That means, that input
fields present in B<MERGER> will unconditionally clobber the respecting
fields in the original state object.

=item B<searchKey KEY, REG>

Returns true if the corresponding values of the input field B<KEY> matches
the regular expression REG

=item B<searchAll REG>

Returns true if any input field matches the regular expression REG.

=item B<existsKey KEY>

Returns true if an input field with the name 'KEY' exists, false otherwise.

=item B<equals OTHER_STATE>

Compares the object to another IWL::Stash(3pm).  Returns true if the two
objects are equal, false otherwise.

=item B<toURIParams>

Converts the object into a string that can be used as URI parameters.
All keys and values are properly URI escaped.  The initial question mark
that separates the parameters from the rest of the URI is I<not>
included.

The method cannot fail.

=item B<toHiddenInputs>

Returns an IWL::Container(3pm) with hidden input fields that completely
represents the object.

The method cannot fail.

=back

=head1 PROTECTED METHODS

=over 4

=item B<_numKeys>

Returns the number of keys.  Rationale: Do not copy memory if we only
need the length of the list of keys.

=item B<_setStateTo>

Sets the internal "__state" variable to the reference passed as a parameter of the function.

=back

=head1 SEE ALSO

IWL::Object(3pm), CGI(3pm), perl(1)


=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
