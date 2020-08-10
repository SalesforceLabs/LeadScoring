trigger evaluateLeadScoringRulesCMInsertOrUpdate on CampaignMember(
    after insert,
    after update
) {
    Set<Id> CampaignMemberIds = new Set<Id>();

    //Loop needed as asynch apex does not allow passage of Sobjects, only Set's
    for (CampaignMember cm : Trigger.new) {
        CampaignMemberIds.add(cm.Id);
    } //for

    //Send that list of created or updated campaign members to the apex class for processing
    system.debug(
        'Future lead scoring class already called? ' +
        LeadScoring.leadScoringClassAlreadyCalled()
    );
    if (LeadScoring.leadScoringClassAlreadyCalled() == false) {
        //        system.debug('# Future Calls until limit hit: '+Limits.getLimitFutureCalls());
        Integer limit1 = Limits.getLimitFutureCalls() - Limits.getFutureCalls();
        if (limit1 > 0) {
            //don't call the method if the limit is reached
            LeadScoring.evaluateCMs(CampaignMemberIds);
        }
    }
}
