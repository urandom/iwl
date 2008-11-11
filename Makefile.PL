use inc::Module::Install;

name            'IWL';
all_from        'lib/IWL.pm';
license         'perl';

requires        'Locale::Messages';
requires        'Locale::TextDomain' => 1.10;
requires        'File::ShareDir' => 0.05;
requires        'HTML::Parser' => 2.25;
requires        'Cwd' => 3.10;

build_requires  'Task::Weaken' => 0.99;
recommends      'Syntax::Highlight::Perl' => 1.00;

install_script  'bin/iwl-install';
install_share   ;

auto_install;

WriteAll;
