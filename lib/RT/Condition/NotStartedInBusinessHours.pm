package RT::Condition::NotStartedInBusinessHours;

use 5.010;
use strict;
use warnings;

require RT::Condition;

use Date::Manip;

use vars qw/@ISA/;
@ISA = qw(RT::Condition);

our $VERSION = '0.1';


=head1 NAME

L<RT::Condition::NotStartedInBusinessHours> - Check for unstarted tickets within
business hours


=head1 DESCRIPTION

This RT Condition will check for tickets which are not started within business
hours.


=head1 SYNOPSIS


=head2 CLI

    rt-crontool
        --search RT::Search::ModuleName
        --search-arg 'The Search Argument'
        --condition RT::Condition::NotStartedInBusinessHours
        --condition-arg 'The Condition Argument'
        --action RT::Action:ActionModule
        --template 'Template Name or ID'


=head1 INSTALLATION

The Perl module L<Date::Manip> is required. You can install it on your RT system
via CPAN:

    cpan Date::Manip

To install this condition, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

or place this script under

    RT_HOME/local/lib/RT/Condition/

where C<RT_HOME> is the path to your RT installation.


=head1 CONFIGURATION


=head2 RT SITE CONFIGURATION

To enabled this condition edit the RT site configuration based in
C<RT_HOME/etc/RT_SiteConfig>:

    Set(@Plugins,qw(RT::Condition::NotStartedInBusinessHours));

To change the standard behavior of Date::Manip you may add to the site configuration:

    Set(%DateManipConfig, (
        'WorkDayBeg', '9:00',
        'WorkDayEnd', '17:00', 
        #'WorkDay24Hr', '0',
        #'WorkWeekBeg', '1',
        #'WorkWeekEnd', '7'
    ));

For more information see L<http://search.cpan.org/~sbeck/Date-Manip-6.25/lib/Date/Manip/Config.pod#BUSINESS_CONFIGURATION_VARIABLES>.


=head2 CONDITION ARGUMENT

This condition needs exactly 1 argument to work.

    --condition RT::Condition::NotStartedInBusinessHours 
    --condition-arg 1

C<1> is the time in hours for escalation.


=head2 EXAMPLE CRON JOB

    rt-crontool 
        --search RT::Search::FromSQL 
        --search-arg "Queue = 'General' AND ( Status = 'new' ) AND Owner = 'Nobody'" 
        --condition RT::Condition::NotStartedInBusinessHours 
        --condition-arg 1 
        --action RT::Action::RecordComment 
        --template 'Unowned tickets'


=head1 AUTHOR

Benjamin Heisig, E<lt>bheisig@synetics.deE<gt>


=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc RT::Condition::NotStartedInBusinessHours


=head1 BUGS

Please report any bugs or feature requests to the L<author|/"AUTHOR">.


=head1 ACKNOWLEDGEMENTS

This script is a fork from L<RT::Condition::UntouchedInBusinessHours> written by
Torsten Brumm.

Special thanks to the synetics GmbH, C<< <http://i-doit.org/> >> for initiating
and supporting this project!


=head1 COPYRIGHT AND LICENSE

Copyright 2011 Benjamin Heisig, E<lt>bheisig@synetics.deE<gt>

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

Request Tracker (RT) is Copyright Best Practical Solutions, LLC.


=head1 SEE ALSO

    Date::Manip


=cut


sub IsApplicable {
    ## Fetch ticket information:
    my $self = shift;
    my $ticketObj = $self->TicketObj;
    my $tickid = $ticketObj->Id;
    my $starts = $ticketObj->StartsObj->AsString;

    my $date = new Date::Manip::Date;

    ## Set Date::Manip's configuration from RT's site configuration:
    my %dateConfig = RT->Config->Get('DateManipConfig');
    # @todo check wether setting exists
    $date->config(%dateConfig);

    ## Compute escalation date:
    my $delta = $date->new_delta();
    $date->parse($starts);
    my $hours = $self->Argument;
    my $businessHours = "in $hours business hours";
    $delta->parse($businessHours);
    my $escalationDate = $date->calc($delta);

    ## Compute actual time:
    my $now = $date->new_date;
    $now->parse('now');

    ## Compare booth times:
    my $cmp = $escalationDate->cmp($now);

    ## Make a decision:
    if ($cmp <= 0) {
        return 1;
    }

    return undef;
}

eval "require RT::Condition::NotStartedInBusinessHours_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/NotStartedInBusinessHours_Vendor.pm});
eval "require RT::Condition::NotStartedInBusinessHours_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/NotStartedInBusinessHours_Local.pm});

1;
