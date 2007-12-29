use inc::Module::Install;

name			'IWL-P2J';
license         'perl';
all_from		'lib/IWL/P2J.pm';

requires		'PPI' => 1.200;
requires		'IWL' => 0.51;

auto_install;

WriteAll;
