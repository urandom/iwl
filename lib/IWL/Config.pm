#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Config;

use strict;

use base qw(Exporter);
use vars qw(@EXPORT @EXPORT_OK %IWLConfig);

=head1 NAME

IWL::Config - provides B<%IWLConfig>

=head1 SYNOPSIS

 use IWL::Config '%IWLConfig';
 print "Skin name: $IWLConfig{SKIN}.\n";

=head1 IWL.CONF

B<iwl.conf> Can be placed inside I<cgi-bin/> directory, or using the I<IWL_CONFIG_FILE> environment variable:
  IWL_CONFIG_FILE=/path/to/my/iwl/config/file/bar.alpha

The following variables may be defined inside the config file:

=over 4

=item B<SKIN>

The skin name to use with IWL. Default value: I<'default'>

=item B<SKIN_DIR>

The directory, containing the skins. It is relative to the server document root. Default value: I<'/iwl/skin'>

=item B<IMAGE_DIR>

The directory, containing the images. It is relative to the current skin directory. Default value: I<'/images'>

=item B<ICON_DIR>

The directory, containing the icons. It is relative to the current skin directory. Default value: I<'/images/icons'>

=item B<ICON_EXT>

The extension of the image icons. Default value: I<'gif'>

=item B<JS_DIR>

The directory, containing all javascript files. It is relative to the server root. Default value: I<'/iwl/jscript'>

=item B<STRICT_LEVEL>

The level of strictness. If greater than 1, attribute names will be checked, and and an exception will be thrown in case the name is illegal. Default value: I<'1'>

=item B<DEBUG>

If true, more debug information will be produced. Default value: I<''>

=item B<JS_WHITELIST>

A comma separated list of config elements, which are allowed to make it into the JavaScript IWL.Config object. The default value includes the previously mentioned config elements.

=item B<RESPONSE_CLASS>

If defined, this class will be used for sending data to the server. See L<IWL::Response> for more details.

=item B<STATIC_URIS>

A colon-separated list of URIs, containing static files. See L<IWL::Static> for more details.

=item B<STATIC_URI_SCRIPT>

A path, relative to the server document root, which points to a script to handle static content via L<IWL::Static>.

=item B<DOCUMENT_ROOT>

The absolute path to the document root. It is used by L<IWL::Static> to locate the static content.

=item I<EXAMPLE CONFIG FILE>

    SKIN = "myskin"
    SKIN_DIR = "/path/to/iwl/skins"
    JS_DIR = "/path/to/iwl/jscript"
    ICON_EXT = "png"

=back

=head1 %IWLConfig

By default, the %IWLConfig variable is filled with default values. If a config file is provided and found, The keys inside the config file will overwrite the default ones. Before the variable is exported, the following keys are mutated:

=over 4

=item B<SKIN_DIR>

It is mutated to I<SKIN_DIR> + '/' + I<SKIN>

=item B<IMAGE_DIR>

It is mutated to I<SKIN_DIR> + '/' + I<SKIN> + I<IMAGE_DIR>

=item B<ICON_DIR>

It is mutated to I<SKIN_DIR> + '/' + I<SKIN> + I<ICON_DIR>

=item B<JS_WHITELIST>

It is mutated to an array reference, by splitting the value by a I<','>

=back

=cut

sub parse_conf {
    my ($path) = @_;

    local *FILE;
    open FILE, $path or (warn "ERROR: Failed to open IWL config in $path: $!" && return);

    while (local $_ = <FILE>) {
	if (/^\s*([^\s]+)\s*=[^"]*"([^"]+)"/) {
	    my ($key, $value) = ($1, $2);
	    $IWLConfig{$key} = $value;
	}
    }
}

if (!exists $IWLConfig{JS_DIR}) {
    # Default values
    %IWLConfig = (
        SKIN         => 'default',
        SKIN_DIR     => '/iwl/skin',
        IMAGE_DIR    => '/images',
        ICON_DIR     => '/images/icons',
        ICON_EXT     => 'gif',
        JS_DIR       => '/iwl/jscript',
        STRICT_LEVEL => 1,
        DEBUG        => '',
        JS_WHITELIST => 'SKIN,SKIN_DIR,IMAGE_DIR,ICON_DIR,ICON_EXT,JS_DIR,STRICT_LEVEL,DEBUG',
    );

    if ($ENV{IWL_CONFIG_FILE} && -s $ENV{IWL_CONFIG_FILE}) {
        parse_conf($ENV{IWL_CONFIG_FILE});
    } elsif (-s 'iwl.conf') {
        parse_conf('iwl.conf');
    } else {
        require Cwd;
        import Cwd qw(abs_path);

        my $script_path = abs_path($0);
        my $conf;

        $script_path =~ s/[^\/]+$//;
        $conf = $script_path . 'iwl.conf';

        parse_conf($conf) if (-s $conf);
    }
    $IWLConfig{SKIN_DIR}    .= '/' . $IWLConfig{SKIN};
    $IWLConfig{IMAGE_DIR}    = $IWLConfig{SKIN_DIR} . $IWLConfig{IMAGE_DIR};
    $IWLConfig{ICON_DIR}     = $IWLConfig{SKIN_DIR} . $IWLConfig{ICON_DIR};
    $IWLConfig{JS_WHITELIST} = [split ',', $IWLConfig{JS_WHITELIST}];
}

@EXPORT_OK = qw(%IWLConfig);
@EXPORT    = qw(%IWLConfig);

1;

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2007  Viktor Kojouharov. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
