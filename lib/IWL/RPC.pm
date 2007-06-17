#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::RPC;

use strict;

use IWL::Object;
use JSON;

=head1 NAME

IWL::RPC - an RPC handler

=head1 INHERITANCE

IWL::RPC

=head1 DESCRIPTION

IWL::RPC provides methods for fetching the CGI parameters, and for providing a link between perl scripts, using AJAX.

=head1 CONSTRUCTOR

IWL::RPC->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self  = bless {}, $class;

    $self->{__isRead} = undef;
    $self->{__params}  = undef;

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

Handles IWL::RPC(3pm) widget specific events. Non-library specific handling code comes is passed via the user specified callback.

Parameters: B<EVENT> - The event name to be handled. B<CALLBACK> - a perl callback to handle the event.

=cut

sub handleEvent {
    my $self = shift;
    my %form = $self->getParams;
    return if !$form{IWLEvent};
    $form{IWLEvent} = jsonToObj($form{IWLEvent});
    while (my $name = shift) {
	my $handler = shift;
	if ($name eq $form{IWLEvent}{eventName}) {
	    $name =~ s/-/::/g;
	    my ($package, $func) = $name =~ /(.*)::([^:]*)$/;
	    eval "require $package";
	    exit 255 if $@;
	    my $method;
	    {
		no strict 'refs';
		$method = *{"${package}::_${func}Event"}{CODE};
	    }
	    if (defined $method) {
		$method->($form{IWLEvent}{params}, $handler);
	    } else {
		$self->__defaultEvent($form{IWLEvent}{params}, $handler);
	    }
	    exit 0;
	}
    }
}

# Internal
#
sub __defaultEvent {
    my ($self, $params, $handler) = @_;

    $params->{userData}{value} = $params->{value} if exists $params->{value};
    my ($data, $user_extras) = $handler->($params->{userData})
        if 'CODE' eq ref $handler;
    $data = {} unless (ref $data eq 'ARRAY' || ref $data eq 'HASH') || $params->{update};

    if ($params->{update}) {
	IWL::Object::printHTMLHeader;
	print $data;
    } else {
	IWL::Object::printJSONHeader;
	print '{data: ' . objToJson($data) . ', user_extras: ' . (objToJson($user_extras) || 'null') . '}';
    }
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
