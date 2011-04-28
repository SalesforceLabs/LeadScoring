/*
Copyright (c) 2011, salesforce.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, Inc. nor the names of its contributors 
    may be used to endorse or promote products derived from this software 
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
OF THE POSSIBILITY OF SUCH DAMAGE.

*/
global class LeadCampaignScoreInitialize implements Database.Batchable<sObject>{

//   global String leadQuery ='Select Id FROM Lead WHERE ConvertedContactID = NULL' ;
   global String cmQuery ='Select Id FROM CampaignMember WHERE ContactID = NULL' ;

   global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(cmQuery);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
        Set<Id> cms=new Set<Id>();
  
        system.debug('Going into the for loop');
        for(sObject s : scope){
            CampaignMember cm=(CampaignMember)s;
            cms.add(cm.Id);
        }//for
    
        try{
            LeadScoring.evaluateCMs2(cms);
            system.debug(cms.size()+' campaign members have been updated!');
        } catch (Exception e) {
            system.debug('The following error occurred when trying to set member Campaign Score to zero: '+e);
        }//try
   }

   global void finish(Database.BatchableContext BC){
       //Send an email once done with success message
       AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id =:BC.getJobId()];
       List<LeadScoringRule__c>lsrs=[Select Id FROM LeadScoringRule__c WHERE Active__c=True AND Type__c='Campaign Member'];
       String emailMessage='';       

       // Send an email to the Apex job's submitter notifying of job completion. 
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       String[] toAddresses = new String[] {a.CreatedBy.Email};
       mail.setToAddresses(toAddresses);
       mail.setSubject('Lead Score initialization for all leads ' + a.Status);
       if(a.NumberOfErrors >0){
           emailMessage=a.TotalJobItems + ' groups of 100 campaign members have been scored.  Campaign Score has been updated on each of the leads associated with those members.  '+ a.NumberOfErrors + ' groups of 100 campaign members had at least 1 error.  Errors likely result from rules with incorrect field names or impossible values.  Please confirm the criteria used in your active campaign member rules. '+lsrs.size()+' active campaign member rules were used as criteria for scoring.';
       }else{
           emailMessage=a.TotalJobItems + ' groups of 100 campaign members have been scored.  Campaign Score has been updated on each of the leads associated with those members.  There were no errors.  '+lsrs.size()+' active campaign member rules were used as criteria for scoring.';
       }        
       mail.setPlainTextBody(emailMessage);
       Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
   
   }

}