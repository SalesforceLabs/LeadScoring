global class LeadScoringInitialize implements Database.Batchable<sObject>{

   global String leadQuery ='Select Id FROM Lead WHERE ConvertedContactID = NULL' ;
//   global String cmQuery ='Select Id FROM CampaignMember WHERE ContactID = NULL' ;

   global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(leadQuery);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
        Set<Id> leads=new Set<Id>();

        system.debug('Going into the for loop');

        for(sObject s : scope){
            lead l=(Lead)s;
            leads.add(l.Id);//add all the relevent lead Id's.
        }//for
    
        try{
            LeadScoring.evaluateLeads2(leads);    
            system.debug(leads.size()+' leads have been scored!');
        } catch (Exception e) {
            system.debug('The following error occurred when trying to set Lead Score to zero: '+e);
        }//try
   }

   global void finish(Database.BatchableContext BC){
       //Send an email once done with success message
       AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id =:BC.getJobId()];
       List<LeadScoringRule__c>lsrs=[Select Id FROM LeadScoringRule__c WHERE Active__c=True AND Type__c='Lead'];
       String emailMessage='';
       // Send an email to the Apex job's submitter notifying of job completion. 
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       String[] toAddresses = new String[] {a.CreatedBy.Email};
       mail.setToAddresses(toAddresses);
       mail.setSubject('Lead Score initialization for all leads ' + a.Status);
       if (a.NumberOfErrors>0){
           emailMessage=a.TotalJobItems + ' groups of 200 leads have been scored.  '+ a.NumberOfErrors + ' groups of 200 leads had 1+ errors.  Errors likely result from rules with incorrect field names or impossible values.  Please confirm the criteria used in your active lead rules.  '+lsrs.size()+' active lead rules were used as criteria for scoring.';           
       }else{
           emailMessage=a.TotalJobItems + ' groups of 200 leads have been scored.  There were no errors.  '+lsrs.size()+' active lead rules were used as criteria for scoring.';           
       } 
       mail.setPlainTextBody(emailMessage);
       Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
   
   }

}