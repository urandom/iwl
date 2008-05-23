#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::RPC;

use strict;

use base 'IWL::Error';

use IWL::Object;
use IWL::JSON qw(toJSON evalJSON);

=head1 NAME

IWL::RPC - an RPC handler

=head1 INHERITANCE

L<IWL::RPC>

=head1 DESCRIPTION

IWL::RPC provides methods for fetching the CGI parameters, and for providing a link between perl scripts, using AJAX.

=head1 CONSTRUCTOR

IWL::RPC->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<parameters>

A hashref of CGI parameters to use, instead of reading for GET/POST parameters.

=item B<deferExit>

If true, the IWL::RPC will return, instead of calling the exit(3pm) function.

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self  = bless {}, $class;

    $self->{__isRead}    = undef;
    $self->{__params}    = $args{parameters} if ref $args{parameters} eq 'HASH';
    $self->{__deferExit} = $args{deferExit} if defined $args{deferExit};

    return $self;
}

=head1 METHODS

=over 4

=item B<getParams>

Returns a hash of all the CGI parameters passed to the script

=cut

sub getParams {
    my $self = shift;

    return %{$self->{__params}} if $self->{__params};

    my (%FORM, $query);
    my $method = lc $ENV{'REQUEST_METHOD'};
    my $content_type = lc $ENV{CONTENT_TYPE} || '';

    my $multipart = $content_type =~ m!multipart/form-data!;

    if ($multipart) {
        binmode(STDIN);
    }

    if ($method eq 'post') {
        if (!$content_type
                || $content_type =~ m!multipart/form-data|form-urlencoded!) {
            $query = $self->__getRequestBody();
        } else {
            warn "Request of unsupported Content-type [$content_type] ".
                "with FORM encryption method: [$method]";
            return;
        }
    } elsif ($method eq 'get' || $method eq 'head' ) {
        my $query_string = $ENV{'QUERY_STRING'} || $ENV{'REDIRECT_QUERY_STRING'};
        $query = \$query_string;
    } else {
        $method ||= 'none';
        warn "Request of unsupported Form encryption method: [$method]";
        return;
    }

    # Multipart form data
    if ($multipart && $query && $$query) {

        my $boundary = $self->__getBoundary();

        my @blocks = split /(?:\r\n)?$boundary/, $$query;

        undef $$query;

        foreach (@blocks) {
            next unless $_;

            s/.*?[Cc]ontent-[Dd]isposition:\s+.+?;\s+(.*?)(?:\n\n|\r\n\r\n|\r\r)//s
                and my $header = $1
                    or next;

            my ($key) = $header =~ /^name="([^"]+)"/;


            # File upload
            if ((my $filename) = $header =~ /filename="([^"]+)"/) {

                $filename =~ s/.*[\:\/\\]//; # Delete path (win)

                my ($type) = $header =~ /[Cc]ontent-[Tt]ype:\s+(\S+)/;

                $FORM{$key} = [\$_, $filename, $type];

                next;
            }

            unless (exists ($FORM{$key})) {
				# Store ordinary form values
                $FORM{$key} = $_;
            } elsif (ref $FORM{$key} eq 'ARRAY') {
				# Multiple select -> list
                push (@{$FORM{$key}}, $_);
            } else {
				# Create multiple select list
                $FORM{$key} = [$FORM{$key}, $_];
            }
        }
    }
    # URL encoded form data
    elsif ($query && defined $$query) {
        $self->queryStringToCGIForm($query, \%FORM);
    }

    $self->{__params} = \%FORM;

    return %FORM;
}

=item B<setParams> (B<PARAMETERS>)

Adds the given parameters to the parameter list of the RPC

Parameters: B<PARAMETERS> - a hash of parameters to add

=cut

sub setParams {
    my ($self, %parameters) = @_;

    $self->{__params}{$_} = $parameters{$_} foreach keys %parameters;

    return $self;
}

=item B<clearParams>

Clears the internal parameter list of the RPC

=cut

sub clearParams {
    my $self = shift;

    $self->{__params} = undef;
    return $self;
}

=item B<queryStringToCGIForm> (B<QUERY>, B<FORM>)

The function splits a query string and fills out the given hash reference

Parameters: B<QUERY> - The query string to be processed. B<FORM> a hash reference, which will be filled from the query string

=cut

sub queryStringToCGIForm {
    my ($self, $query, $FORM) = @_;

    $FORM = {} unless (ref $FORM eq 'HASH');
    return unless $query && $$query;

    foreach (split /&/, $$query) {
        my ($key, $value) = split(/=/, $_);

        if (defined $value) {
            $value =~ tr/+/ /;

            # Line breaks are represented as "CR LF" pairs (i.e., `%0D%0A').
            $value =~ s/%0D%0A/\n/g;

            $value =~ s/%([a-f0-9]{2})/pack'C',hex$1/eig; # HEX -> ASCII

            # key conversion
            $key =~ s/%([a-f0-9]{2})/pack'C',hex$1/eig;	# HEX -> ASCII
        }

        $self->__pushValue($key, $value, $FORM);
    }
    return $FORM;
}

=item B<handleEvent> (B<EVENT>, B<CALLBACK>)

Handles L<IWL::RPC> widget specific events. Non-library specific handling code comes is passed via the user specified callback.

Parameters: B<EVENT> - The event name to be handled. B<CALLBACK> (I<parameters>, [I<id>, I<elementData>]) - a perl callback, called by the event handler.

Unless provided by the class, to which the event belongs, all events are processed by the default event handler. The handler calls the perl B<CALLBACK>, passing the I<parameters> hashref as a first argument, as well as the I<id> of the emitting element (if it has an ID), and the collected I<elementData> (if the I<collectData> option was passed when registering the event. See L<IWL::RPC::Request::registerEvent> for more information). The B<CALLBACK> has to return I<DATA>, and I<EXTRAS>. The I<DATA> can be an L<IWL::Object>, an arrayref or hashref, which will be serialized into JSON, or string data. The I<EXTRAS> is in the form of a hashref, with keys and values that might be needed by processing client-side code.

=cut

sub handleEvent {
    my $self = shift;
    my %form = $self->getParams;
    return if !$form{IWLEvent};
    $form{IWLEvent} = evalJSON($form{IWLEvent}, 1);
    while (my $name = shift) {
	my $handler = shift;
	if ($name eq $form{IWLEvent}{eventName}) {
	    $name =~ s/-/::/g;
	    my ($package, $func) = $name =~ /(.*)::([^:]*)$/;
	    eval "require $package";
            ($self->{__deferExit}
                ? return $self->_pushFatalError($@)
                : exit 255) if $@;
	    my $method;
	    {
		no strict 'refs';
		$method = *{"${package}::_${func}Event"}{CODE};
	    }
	    if (defined $method) {
		$method->($form{IWLEvent}, $handler);
	    } else {
		$self->__defaultEvent($form{IWLEvent}, $handler);
	    }
            $self->{__deferExit} ? return $self : exit 0;
	}
    }
    return;
}

=item B<eventResponse> (B<EVENT>, B<RESPONSE>)

Used by widget event handlers to return a response for for a given event. It is only useful for widget implementation.

Parameters: B<EVENT> - the RPC event. B<RESPONSE> - the response for the event. The response is a hash, with the following recognized key-value pairs:

B<NOTE>: This method can be used as a class method, or as an instance method.

=over 8

=item B<data>

The main response data

=item B<extras>

Any extra information that the client-side code should expect

=item B<header>

Additional header values for the response

=back

=cut

sub eventResponse {
    shift if 'IWL::RPC' eq ref $_[0];
    my ($event, $responseData) = @_;
    my $data = $responseData->{data};
    my $extras = $responseData->{extras};
    my $header = $responseData->{header} || {};
    my $response = IWL::Response->new;

    if ($event->{options}{update}) {
        if (UNIVERSAL::isa($data, 'IWL::Object')) {
            $data->send(type => 'html');
        } else {
            $response->send(
                content => $data,
                header => {%{IWL::Object::getHTMLHeader()}, %$header}
            );
        }
    } else {
        $response->send(
            content => '{data: ' . $data . ', extras: ' . (toJSON($extras) || 'null') . '}',
            header => {%{IWL::Object::getJSONHeader()}, %$header}
        );
    }
}

# Internal
#
sub __defaultEvent {
    my ($self, $event, $handler) = @_;

    my ($data, $extras) = ('CODE' eq ref $handler)
      ? $handler->($event->{params}, $event->{options}{id},
        $event->{options}{collectData} ? $event->{options}{elementData} : undef)
      : (undef, undef);
    if (UNIVERSAL::isa($data, 'IWL::Object')) {
        $data = $data->getJSON unless $event->{options}{update};
    } elsif (ref $data eq 'ARRAY' || ref $data eq 'HASH') {
        $data = toJSON($data);
    } else {
        $data = qq|"$data"| unless $event->{options}{update};
    }

    $self->eventResponse($event, {data => $data, extras => $extras});
}

sub __getBoundary {
    my $self = shift;

    (undef, my $boundary) = $ENV{CONTENT_TYPE}
        =~ /boundary=(\"|)([a-zA-Z0-9_\'\(\)+,\-\.\/:=?]+)\1$/; # Referring to RFC2046
    $boundary = quotemeta '--'. $boundary; # Boundary always starts with '--'
    return $boundary;
}

# Returns undef if request method or content type are not suitable.
# Otherwise, returns a reference to a variable holding the
# content of the request body.
sub __getRequestBody {
    my ($self, $size_check_off) = @_;

	warn ":__getRequestBody(): Attempt to read from STDIN more than once."
            and return
                if $self->{__isRead}++;
    my $size = $ENV{CONTENT_LENGTH};
    my $type = lc $ENV{CONTENT_TYPE} || '';

    return unless lc $ENV{'REQUEST_METHOD'} eq 'post'
        && (!$type || $type =~ m!multipart/form-data|form-urlencoded!);

    unless ($size_check_off) {
        my $max_size = $self->{__maxSize} || $size;

        if ($size > $max_size) {
            warn "request size ($size bytes) exceeds maximum size ($max_size bytes)";
            sleep 5;
            warn "Request too large.";
        }
    }

    # 'POST' -> Read from STDIN:
    my $body;
    read(STDIN, $body, $size);

    return \$body;
}

sub __pushValue {
    my ($self, $key, $value, $hash) = @_;

    unless (exists $hash->{$key}) {
        $hash->{$key} = $value;
    } elsif (ref ($hash->{$key})) {
        push @{$hash->{$key}}, $value;
    } else {
        $hash->{$key} = [$hash->{$key}, $value];
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
