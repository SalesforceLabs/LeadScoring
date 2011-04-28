trigger evaluateLeadScoringRulesCMDelete on CampaignMember (before Delete) {
    Set<Id> CampaignMemberIds=new Set<Id>();
     
    //Loop needed as asynch apex does not allow passage of Sobjects, only Set's
    //Only add non-converted lead CM's to the set as contacts shouldn't be processed
    for (CampaignMember cm:trigger.old){
        if (cm.ContactID==null){
            CampaignMemberIds.add(cm.Id); 
        }    
    }//for

    //Send that list of created or updated campaign members to the apex class for processing
//    system.debug('Future lead scoring class already called? '+LeadScoring.leadScoringClassAlreadyCalled());
    if (LeadScoring.leadScoringClassAlreadyCalled()==False){
        LeadScoring.deletedCMs(CampaignMemberIds);    
    }//if
}