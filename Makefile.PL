use inc::Module::Install;

RTx 'RT-Condition-NotStartedInBusinessHours';

all_from 'lib/RT/Condition/NotStartedInBusinessHours.pm';
license 'perl';
readme_from;
repository 'git://git.benjaminheisig.net/rt-condition-notstartedinbusinesshours.git';

requires 'Date::Manip' => '6.25';
auto_install();

sign;
&WriteAll;
