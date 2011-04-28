trigger evaluateLeadScoringRulesLeadInsertOrUpdate on Lead (After insert, After update) {

    Set<Id> leadIds=new Set<Id>();
    Map<Id, Double> leadScores=new Map<Id,Double>();    

    //Needed as asynch apex does not allow passage of Sobjects, only Set's
    for (Lead l:trigger.new){
        leadIds.add(l.Id);
    }//for

    //Send that list of created or updated campaign members to the apex class for processing
    system.debug('Future lead scoring method evaluateLeads already called? '+LeadScoring.leadScoringClassAlreadyCalled());
    if (LeadScoring.leadScoringClassAlreadyCalled()==False){
//        system.debug('# Future Calls until limit hit: '+Limits.getLimitFutureCalls());
        Integer limit1 = Limits.getLimitFutureCalls() - Limits.getFutureCalls();
        if (limit1>0){//don't call the method if the limit is reached
            LeadScoring.evaluateLeads(leadIds);    
        }    
    }    
}//trigger