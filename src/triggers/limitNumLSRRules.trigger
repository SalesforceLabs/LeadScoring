trigger limitNumLSRRules on LeadScoringRule__c (before Insert, before Update) {
    Integer leadRuleLimit=200;
    Integer cmRuleLimit=450;
    List<LeadScoringRule__c> activeLeadRules=[SELECT Id, Active__C FROM LeadScoringRule__c WHERE Type__c='Lead' AND Active__c=True];
    List<LeadScoringRule__c> activeCMRules=[SELECT Id, Active__C FROM LeadScoringRule__c WHERE Type__c='Campaign Member' AND Active__c=True];
    Integer numLeadRules=activeLeadRules.size();
    Integer numCMRules=activeCMRules.size();
    Boolean overLeadRuleLimit=(numLeadRules>leadRuleLimit);
    Boolean overCMRuleLimit=(numCMRules>cmRuleLimit);
    LeadScoringRule__c lsr = new LeadScoringRule__c();
    
    for (Integer i=0;i<trigger.new.size();i++){//for
        lsr=trigger.new[i];
        if(Trigger.isInsert){//if 1
            if(lsr.Type__c=='Lead'&&lsr.Active__c==True){//if 2
                numLeadRules++;
                overLeadRuleLimit=(numLeadRules>leadRuleLimit);
                if(overLeadRuleLimit==True){//if 3
                    lsr.adderror('Error: Lead active rule limit exceeded.  Limit: '+leadRuleLimit+' active lead rules.  To create a new lead rule, first deactivate or delete another active lead rule.');
                }//if 3   
            } else if (lsr.Type__c=='Campaign Member'&&lsr.Active__c==True){
                numCMRules++;    
                overCMRuleLimit=(numCMRules>cmRuleLimit);
                if(overCMRuleLimit==True){
                    lsr.adderror('Error: Campaign member active rule limit exceeded.  Limit: '+cmRuleLimit+' active campaign member rules. To create a new campaign member rule, first deactivate or delete another campaign member rule.');
                }//if 3
            }//if 2    
        }//if 1
        if(Trigger.isUpdate){//if 1
            LeadScoringRule__c lsrOld=trigger.old[i];
            if(lsrOld.Active__c==True){//if 2
                if(lsrOld.Type__c=='Lead'&&overLeadRuleLimit==True&&lsr.Active__c==True){//if 3
                        lsr.adderror('Error: Lead active rule limit exceeded.  Limit: '+leadRuleLimit+' active lead rules.  To edit any active lead rules, first deactivate or delete another active lead rule.');
                }else if (lsrOld.Type__c=='Campaign Member'&overCMRuleLimit==True&&lsr.Active__c==True){
                    lsr.adderror('Error: Campaign member active rule limit exceeded.  Limit: '+cmRuleLimit+' active campaign member rules.  To edit any active campaign member rules, first deactivate or delete another active campaign member rule.');                    
                }//if 3        
            }else if(lsrOld.Active__c==False){
                if(lsr.Active__c==True){//if 3
                    if (lsrOld.Type__c=='Lead'){//if 4
                        numLeadRules++;
                        overLeadRuleLimit=(numLeadRules>leadRuleLimit);
                        if(overLeadRuleLimit==True){//if 5
                            lsr.adderror('Error: Lead active rule limit exceeded.  Limit: '+leadRuleLimit+' active lead rules.  To activate inactive lead rules, first deactivate or delete another active lead rule.');
                        }//if 5    
                    }else if(lsrOld.Type__c=='Campaign Member'){
                        numCMRules++;
                        overCMRuleLimit=(numCMRules>cmRuleLimit);
                        if(overLeadRuleLimit==True){//if 5
                            lsr.adderror('Error: Campaign member active rule limit exceeded.  Limit: '+cmRuleLimit+' active campaign member rules.  To activate inactive campaign member rules, first deactivate or delete another active campaign member rule.');
                        }//if 5    
                    } //if 4    
                }//if 3        
            }//if 2
        }//if 1      
    }//for   
}