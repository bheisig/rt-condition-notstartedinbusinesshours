package RT::Condition::NotStartedInBusinessHours;

use 5.010;
use strict;
use warnings;

require RT::Condition;

use Date::Manip;

use vars qw/@ISA/;
@ISA = qw(RT::Condition);

our $VERSION = '0.2';


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

This condition based on the following modules:

    RT >= 4.0.0
    Date::Manip >= 6.25

To install this condition run the following commands:

    perl Makefile.PL
    make
    make test
    make install

or place this script under

    RT_HOME/local/lib/RT/Condition/

where C<RT_HOME> is the path to your RT installation.

You may additionally make this condition available in RT's web UI as a Scrip
Condition:

    make initdb


=head1 CONFIGURATION


=head2 RT SITE CONFIGURATION

To enabled this condition edit the RT site configuration based in
C<RT_HOME/etc/RT_SiteConfig>:

    Set(@Plugins,qw(RT::Condition::NotStartedInBusinessHours));

To change the standard behavior of Date::Manip you may add to the site
configuration:

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

You can find documentation for this module with the C<perldoc> command.

    perldoc RT::Condition::NotStartedInBusinessHours

You can also look for information at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/RT-Condition-NotStartedInBusinessHours/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RT-Condition-NotStartedInBusinessHours>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RT-Condition-NotStartedInBusinessHours>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RT-Condition-NotStartedInBusinessHours>

=back


=head1 BUGS

Please report any bugs or feature requests to the L<author|/"AUTHOR">.

The language setting of the current user (obviously C<root>) has to be set to
C<en> (English) or left empty (system default is English). Otherwise parsing
ticket's C<Starts> date by C<Date::Manip> won't work.


=head1 ACKNOWLEDGEMENTS

This script is a fork from L<RT::Condition::UntouchedInBusinessHours> written by
Torsten Brumm.

Special thanks to the synetics GmbH, C<< <http://i-doit.org/> >> for initiating
and supporting this project!


=head1 COPYRIGHT AND LICENSE

Copyright 2012 synetics GmbH, E<lt>http://i-doit.org/E<gt>

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

Request Tracker (RT) is Copyright Best Practical Solutions, LLC.


=head1 SEE ALSO

    RT
    Date::Manip


=cut


sub IsApplicable {
    my $self = shift;

    ## Enforce English language. Otherwise parsing ticket's 'Starts' date by
    ## Date::Manip won't work:
    my $language = substr($self->CurrentUser->Lang, 0, 2);
    if ($language ne '' && $language ne 'en') {
        $RT::Logger->error(
            "This RT condition failed because current user '" .
            $self->CurrentUser->Name .
            "' has the unsupported language setting '" .
            $self->CurrentUser->Lang .
            "'. It should be set to 'en' (English) or left empty (system default is English)."
        );
        return undef;
    }

    ## Fetch ticket information:
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
