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
@isTest
private class LeadScoringTests{
    //used to run the tests quicker by ignoring the batch tests with 90 leads & 80 rules
    static Boolean runBatchTests=true;
    
    static campaign c;//used to store the campaign value for creaing CM's later if needed

    
    //utility class to create dummy data to test
    public static List<Lead> createLeads(Long NumLeads, String LN, String Cmpy, Boolean OptedOutOfEmail, String LeadSrc, Boolean OptOutFax, Double AnnualRev) {
        List<Lead> leads = new List<Lead>{};
        Integer i;
        for (i=0;i<numLeads;i++){
            Lead l = new Lead(LastName=LN+i, Company=Cmpy, HasOptedOutOfEmail=OptedOutOfEmail, LeadSource=LeadSrc, HasOptedOutOfFax=OptOutFax, AnnualRevenue=AnnualRev);
            leads.add(l);
        }//for
        insert leads;

        return leads;
    }//createLeads

    public static void createCampaign(String CampaignName){
        Campaign c1= new Campaign(Name=CampaignName);
        insert c1;
        c=c1;//lets the campaign be referenced in the method that calls this method
    }

    public static LeadScoringRule__c createLSR(Boolean Active, String LSRType, Double LSRScore, String LSRFN, String LSROperator, String LSRValue) {
        LeadScoringRule__c lsr;
        if (c==null){
            lsr=new LeadScoringRule__c(Active__c=Active, Type__c=LSRType, Score_Change__c=LSRScore, Field_Name__c=LSRFN, Operator__c=LSROperator, Value__c=LSRValue);
        } else {
            lsr=new LeadScoringRule__c(Active__c=Active, Type__c=LSRType, Campaign__c=c.id, Score_Change__c=LSRScore, Field_Name__c=LSRFN, Operator__c=LSROperator, Value__c=LSRValue);    
        }
        return lsr;
    }//createLSR

    public static List<CampaignMember> createCMs(Long numLeads, Id CID,List<Lead> leads,String cmStatus) {
       List<CampaignMember> campaignMembers = new List<CampaignMember>{};
       
       for(Integer i = 0; i < numLeads; i++){
            Id LeadIdi=leads[i].id;
            CampaignMember cm=new CampaignMember( CampaignId=CID, LeadId=LeadIdi, Status=cmStatus);
            campaignmembers.add(cm);
       }//for
        
       return campaignMembers;

    }//createCMs

    public static void cleanUpTestData() {
        List<LeadScoringRule__c> lsrs=[Select ID from LeadScoringRule__c LIMIT 500];
        delete lsrs;
    }//cleanUpTestData
       
    static testMethod void verifyLeadStringEquals(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>{};
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='Company';
        String LSROperator='eQuals';//testing capitalization as well
        String LSRValue='comPany';//testing capitalization as well
        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();

        String LN='TestLead';
        String Company=LSRValue;
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='';
        Double AnnualRev=1000;
        
        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Company='asdf';
        List<Lead> leads2=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertEquals(l.Lead_Score__c,LSRScore);
        l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads2[0].Id LIMIT 1];
        system.assertNOTEquals(l.Lead_Score__c,LSRScore);
    }//verifyLeadStringEquals
    
    static testMethod void verifyLeadStringNotEqualTo(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='Company';
        String LSROperator='Not Equal To';
        String LSRValue='TestString';
        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();

        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Company='TestString';
        List<Lead> leads2=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertEquals(l.Lead_Score__c,LSRScore);
        l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads2[0].Id LIMIT 1];
        system.assertNOTEquals(l.Lead_Score__c,LSRScore);
    }//verifyLeadStringNotEqualTo

    static testMethod void verifyLeadPicklistContains(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='LeadSource';
        String LSROperator='Contains';
        String LSRValue='we';//note testing case sensitivity of the LSR value here
        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        LeadSource='Referral';
        List<Lead> leads2=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertEquals(l.Lead_Score__c,LSRScore);
        l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads2[0].Id LIMIT 1];
        system.assertNOTEquals(l.Lead_Score__c,LSRScore);
    }//verifyLeadPicklistContains

    static testMethod void verifyLeadPicklistDoesNotContain(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='LeadSource';
        String LSROperator='Does Not Contain';
        String LSRValue='eferr';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        LeadSource='ReFerral';//note testing case sensitivity here as well
        List<Lead> leads2=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();


        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertEquals(l.Lead_Score__c,LSRScore);
        l=[Select Id, LeadSource,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads2[0].Id LIMIT 1];
        system.debug('Lead Source: '+l.LeadSource +' should not contain '+LeadSource);
        system.assertNOTEquals(l.Lead_Score__c,LSRScore);
    }//verifyLeadPicklistDoesNotContain

    static testMethod void verifyLeadStringStartsWith(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='LastName';
        String LSROperator='Starts With';
        String LSRValue='Test';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        LN='LeadTest';
        List<Lead> leads2=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertEquals(l.Lead_Score__c,LSRScore);
        l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads2[0].Id LIMIT 1];
        system.assertNOTEquals(l.Lead_Score__c,LSRScore);
    }//verifyLeadStringStartsWith

  static testMethod void verifyLeadBooleanEquals(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Campaign Member';
        String LSRFieldName='HasResponded';
        String LSROperator='Equals';
        String LSRValue='True';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;
        String cmStatus='Responded';//this drives HasResponded=True

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        createCampaign(CampaignName);
        List<CampaignMember> cms=createCMs(numLeads, c.Id,leads,cmStatus);
        List<Lead> leads2=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        cmStatus='Sent';
        List<CampaignMember> cms2=createCMs(numLeads, c.Id,leads2,cmStatus);        
        
        Test.StartTest();
        insert cms;
        insert cms2;
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertEquals(l.Campaign_Score__c,LSRScore);
        l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads2[0].Id LIMIT 1];
        system.assertNOTEquals(l.Campaign_Score__c,LSRScore);
    }//verifyLeadBooleanEquals
    
  static testMethod void verifyLeadBooleanNotEqualTo(){
       Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Campaign Member';
        String LSRFieldName='HasResponded';
        String LSROperator='Not Equal To';
        String LSRValue='True';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;
        String cmStatus='Sent';//this drives HasResponded=True

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        createCampaign(CampaignName);
        List<CampaignMember> cms=createCMs(numLeads, c.Id,leads,cmStatus);
        List<Lead> leads2=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        cmStatus='Responded';
        List<CampaignMember> cms2=createCMs(numLeads, c.Id,leads2,cmStatus);        
        
        Test.StartTest();
        insert cms;
        insert cms2;
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertEquals(l.Campaign_Score__c,LSRScore);
        l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads2[0].Id LIMIT 1];
        system.assertNOTEquals(l.Campaign_Score__c,LSRScore);
    }//verifyLeadBooleanNotEqualTo

  static testMethod void verifyLeadDoubleEquals(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='AnnualRevenue';
        String LSROperator='Equals';
        String LSRValue='1000';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        AnnualRev=2000;
        List<Lead> leads2=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertEquals(l.Lead_Score__c,LSRScore);
        l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads2[0].Id LIMIT 1];
        system.assertNOTEquals(l.Lead_Score__c,LSRScore);
    }//verifyLeadDoubleEquals

  static testMethod void verifyLeadDoubleNotEqualTo(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='AnnualRevenue';
        String LSROperator='Not Equal To';
        String LSRValue='999';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        AnnualRev=999;
        List<Lead> leads2=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertEquals(l.Lead_Score__c,LSRScore);
        l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads2[0].Id LIMIT 1];
        system.assertNOTEquals(l.Lead_Score__c,LSRScore);
    }//verifyLeadDoubleNotEqualTo

  static testMethod void verifyLeadDoubleGreaterThan(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='AnnualRevenue';
        String LSROperator='Greater Than';
        String LSRValue='999';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        AnnualRev=998;
        List<Lead> leads2=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertEquals(l.Lead_Score__c,LSRScore);
        l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads2[0].Id LIMIT 1];
        system.assertNOTEquals(l.Lead_Score__c,LSRScore);
    }//verifyLeadDoubleGreaterThan

  static testMethod void verifyLeadDoubleGreaterorEqual(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='AnnualRevenue';
        String LSROperator='Greater or Equal';
        String LSRValue='1000';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        AnnualRev=999;
        List<Lead> leads2=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        AnnualRev=1001;
        List<Lead> leads3=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();
        
        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertEquals(l.Lead_Score__c,LSRScore);
        l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads2[0].Id LIMIT 1];
        system.assertNOTEquals(l.Lead_Score__c,LSRScore);
        l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads3[0].Id LIMIT 1];
        system.assertEquals(l.Lead_Score__c,LSRScore);
    }//verifyLeadDoubleGreaterorEqual

  static testMethod void verifyLeadDoubleLessOrEqual(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='AnnualRevenue';
        String LSROperator='Less Or Equal';
        String LSRValue='1000';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        AnnualRev=1001;
        List<Lead> leads2=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        AnnualRev=999;
        List<Lead> leads3=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertEquals(l.Lead_Score__c,LSRScore);
        l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads2[0].Id LIMIT 1];
        system.assertNOTEquals(l.Lead_Score__c,LSRScore);
        l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads3[0].Id LIMIT 1];
        system.assertEquals(l.Lead_Score__c,LSRScore);
    }//verifyLeadDoubleLessOrEqual

  static testMethod void verifyLeadDoubleLessThan(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='AnnualRevenue';
        String LSROperator='Less Than';
        String LSRValue='1001';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        AnnualRev=1002;
        List<Lead> leads2=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertEquals(l.Lead_Score__c,LSRScore);
        l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads2[0].Id LIMIT 1];
        system.assertNOTEquals(l.Lead_Score__c,LSRScore);
    }//verifyLeadDoubleLessThan

  static testMethod void verifyLeadDateEquals(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='CreatedDate';
        String LSROperator='Equals';
        String LSRValue=String.valueOf(DateTime.now());

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
//        system.assertEquals(l.Lead_Score__c,LSRScore);
//Date criteria don't yet work
        //Negative test in next test method
    }//verifyLeadDateEquals

  static testMethod void verifyLeadDateEqualsNegativeTest(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='CreatedDate';
        String LSROperator='Equals';
        DateTime dateValue=DateTime.now();
        DateTime dateValue2=dateValue.addDays(3);
        String LSRValue=String.valueOf(dateValue2);

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, CreatedDate,Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.debug('Created Date: '+l.CreatedDate+' ; LSRValue : '+LSRValue);
        system.assertNOTEquals(l.Lead_Score__c,LSRScore);
    }//verifyLeadDateEqualsNegativeTest

 static testMethod void verifyLeadDateNotEqualTo(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='CreatedDate';
        String LSROperator='Not Equal To';
        Date dateValue=Date.today();
        Date dateValue2=dateValue.addDays(2);
        String LSRValue=String.valueOf(dateValue2);

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
//        system.assertEquals(l.Lead_Score__c,LSRScore);
//Date criteria don't yet work
        //Negative test in next test method
    }//verifyLeadDateNotEqualTo

  static testMethod void verifyLeadDateNotEqualToNegativeTest(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='CreatedDate';
        String LSROperator='Not Equal To';
        String LSRValue=String.valueOf(Date.today());

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertNOTEquals(l.Lead_Score__c,LSRScore);
    }//verifyLeadDateNotEqualToNegativeTest

  static testMethod void verifyDupeRulesDoesntGack(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='Company';
        String LSROperator='Equals';
        String LSRValue='Company';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertEquals(l.Lead_Score__c,LSRScore*2);
    }//verifyDupeRulesDoesntGack

  static testMethod void verifyNullFieldNameDoesntGack(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName=null;
        String LSROperator='Equals';
        String LSRValue='Company';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        try{
            insert lsrs;
        } catch(Exception e){
            system.debug('LSR insert failed as expected due to null FieldName ' + e);       
        }
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertNOTEquals(l.Lead_Score__c,LSRScore);
    }//verifyNullFieldNameDoesntGack
    
static testMethod void verifyNullOperatorDoesntGack(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='Company';
        String LSROperator=null;
        String LSRValue='Company';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertNOTEquals(l.Lead_Score__c,LSRScore);
    }//verifyNullOperatorDoesntGack

  static testMethod void verifyInvalidFieldNameDoesntGack(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='bob';
        String LSROperator='Equals';
        String LSRValue='Company';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        try{
            lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        } catch (exception e){
            Boolean expectedExceptionThrown=e.getMessage().contains('System.DmlException: Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Error: Invalid Lead field name entered:');
            system.AssertEquals(expectedExceptionThrown, true);
        }
    }//verifyInvalidFieldNameDoesntGack
    
    static testMethod void verifyInvalidOperatorDoesntGack(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='Company';
        String LSROperator='bob';
        String LSRValue='Company';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertNOTEquals(l.Lead_Score__c,LSRScore);
    }//verifyInvalidOperatorDoesntGack

    static testMethod void verifyFieldNameCapitalsDontGack(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='Company';
        String LSROperator='Equals';
        String LSRValue='Company';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        LSRFieldName='company';
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        
        Test.StartTest();
        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        Test.StopTest();

        Lead l=[Select Id, Company,Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertEquals(l.Lead_Score__c,LSRScore*2);
    }//verifyFieldNameCapitalsDontGack

    static testMethod void verifyDeleteTrigger(){
    //test doesn't yet work due to asynch apex issues - need to create the lead & members 
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Campaign Member';
        String LSRFieldName='Status';
        String LSROperator='Equals';
        String LSRValue='Sent';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        String LN='TestLead';
        String Company='Company';
        Boolean HasOptedOutOfEmail=TRUE;
        String LeadSource='Web';
        Boolean HasOptedOutOfFax=FALSE;
        String CampaignName='2009-Q3-Event-Dreamforce 2009';
        Double AnnualRev=1000;

        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        insert lsrs;
        createCampaign(CampaignName);

        leads=createLeads(numLeads,LN,Company,HasOptedOutOfEmail, LeadSource, HasOptedOutOfFax,AnnualRev);
        List<CampaignMember> cms=createCMs(NumLeads, c.Id,leads,'Sent');

        test.startTest();
        insert cms;
        delete cms;//timing of this doesn't work as both are asynch processes so the method doesn't finish before the delete occurs
        test.stopTest();
        Lead l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
        system.assertEquals(l.Campaign_Score__c,null);
    }//verifyDeleteTrigger    

    static testMethod void verifyLSRLabelAndName(){
        Boolean Active=True;
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='Status';
        String LSROperator='Equals';
        String LSRValue='Open';
        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();

        cleanUpTestData();
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    

        insert lsrs;
        LeadScoringRule__c lsr=[Select Id, Name, Field_Label__c, Field_Name__c FROM LeadScoringRule__c WHERE Id=:lsrs[0].Id LIMIT 1];
        //Check it first upon insert
        system.assertEquals(lsr.Field_Label__c,Schema.SObjectType.CampaignMember.fields.getMap().get(LSRFieldName).getDescribe().getLabel());
        
        LSRFieldName='email';
        lsr.Field_Name__c=LSRFieldName;
        update lsr;
        lsr=[Select Id, Name, Field_Label__c, Field_Name__c FROM LeadScoringRule__c WHERE Id=:lsrs[0].Id LIMIT 1];
        //Check again after update
        system.assertEquals(lsr.Field_Label__c,Schema.SObjectType.Lead.fields.getMap().get(LSRFieldName).getDescribe().getLabel());
    }//verifyLSRLabelAndName


    public static testMethod void testLeadScoringRulesController() {
        
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.LeadScoringRulesEdit;
        
        //In this case, the Visualforce page named 'success' is the starting point of this test method. 
        Test.setCurrentPage(pageRef);

        LeadScoringRule__c lsr=new LeadScoringRule__c();
        lsr.Type__c='Campaign Member';
        lsr.Field_Name__c='HasResponded';//this will run the checkbox check
        lsr.Score_Change__c=5;
        lsr.Operator__c='Equals';
        lsr.Value__c='True';

        ApexPages.StandardController sc = new ApexPages.StandardController(lsr);
        LeadScoringRulesController scExt = new LeadScoringRulesController(sc);
        scExt.getLSRFieldNames();
        scExt.getLSROperator();
        scExt.getValuePicklistOptions();
        
        lsr.Type__c='Lead';
        lsr.Field_Name__c='Status';//this will run the checkbox check
        apexPages.StandardController sc2 = new ApexPages.StandardController(lsr);
        LeadScoringRulesController scExt2 = new LeadScoringRulesController(sc2);
        scExt.getLSRFieldNames();
        scExt.getLSROperator();
        scExt2.getValuePicklistOptions();
        
        scExt.savenew();//test no exception upon saving & creating a new record
                        //Also having active=false by default should ensure the limits trigger doesn't gack if active = false.
                        //Note due to Apex test deficiencies the limit can't be tested directly (limited to 100 record inserts in 1 method)
    }//testLeadScoringRulesController        

   public static testMethod void testLeadScoringInitialize () {//tests the batch apex method for campaign members
        if(runBatchTests==True){//if 1
            Long NumLeads=1;//test methods can't test more than ~100 records inserted, so no point in even trying as the app scales over 200 lead rules
            Integer i;
            List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
            cleanUpTestData();
            
            List<Lead> leads=createLeads(NumLeads, 'Lead', 'Company', False, 'Web', False,1000);
                   
            Long NumLeadRules=10;//too close to the DML limit for tests.  
            for (i=0;i<NumLeadRules;i++){
                lsrs.add(createLSR(TRUE, 'Lead', 1, 'Company', 'equals', 'Company'));
            }    

                   
            insert lsrs;
            
           Test.StartTest(); 
            LeadScoringInitialize initLS=new LeadScoringInitialize ();
         //   initLS.leadQuery='Select Id FROM Lead WHERE Id IN :leads LIMIT 1';
         initLS.leadQuery='Select Id FROM Lead  LIMIT 10';
 
             
//                Id batchprocessId=Database.executeBatch(initLS,200);
                Database.executeBatch(initLS, 10);
            Test.StopTest();
            
            Lead l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
            
            system.debug('Assert Lead_Score__c = 100.  Actual: ' +l.Lead_Score__c);
            System.AssertEquals(l.Lead_Score__c,NumLeadRules);
            system.debug('Assert Total_Lead_Score__c = '+NumLeadRules+'.  Actual:' +l.Total_Lead_Score__c);
            System.AssertEquals(l.Total_Lead_Score__c,NumLeadRules);
        }//if 1                    
   }//testLeadScoringInitialize 

   public static testMethod void testLeadCampaignScoreInitialize () {//tests the batch apex method for campaign members
       if(runBatchTests==True){//if 1
            Long NumLeads=1;//test methods can't test more than ~100 records inserted, so no point in even trying as the app scales over 200 lead rules
            Integer i;
            Integer cmScore=2;
            List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();

            cleanUpTestData();
            
            List<Lead> leads=createLeads(NumLeads, 'Lead', 'Company', False, 'Web', False,1000);
            createCampaign('Campaign 1');
            List<CampaignMember> cms=createCMs(NumLeads, c.Id,leads,'Sent');
            insert cms;
                   
            Long NumCMRules=10;
            for (i=0;i<NumCMRules;i++){
                lsrs.add(createLSR(TRUE, 'Campaign Member', cmScore, 'Status', 'equals', 'Sent'));
            }    
            insert lsrs;
             
            Test.StartTest();      
            LeadCampaignScoreInitialize initCS=new LeadCampaignScoreInitialize();
      //      initCS.cmQuery='Select Id FROM CampaignMember WHERE CampaignID='+c.Id+' LIMIT 1';
      initCS.cmQuery='Select Id FROM CampaignMember   LIMIT 10';
            
            
//                Id batchprocessId=Database.executeBatch(initCS,200);
                 Database.executeBatch(initCS, 10);
            Test.StopTest();
            
            
            Lead l=[Select Id, Lead_Score__c, Campaign_Score__c, Total_Lead_Score__c FROM Lead WHERE Id=:leads[0].Id LIMIT 1];
            CampaignMember cm=[Select Id, Campaign_Score__c FROM CampaignMember WHERE LeadId=:leads[0].Id LIMIT 1];
            
            system.debug('Assert Lead_Score__c = 0.  Actual: ' +l.Lead_Score__c);
            System.AssertEquals(l.Lead_Score__c,0);
            system.debug('Assert cm Campaign_Score__c = '+cmScore+'.  Actual: ' +cm.Campaign_Score__c);
            System.AssertEquals(cm.Campaign_Score__c,cmScore*NumCMRules);
            system.debug('Assert lead Campaign_Score__c = '+cmScore+'.  Actual: ' +l.Campaign_Score__c);
            System.AssertEquals(l.Campaign_Score__c,cmScore*NumCMRules);
            system.debug('Assert Total_Lead_Score__c = '+NumCMRules+cmScore+'.  Actual:' +l.Total_Lead_Score__c);
            System.AssertEquals(l.Total_Lead_Score__c,NumCMRules*cmScore);
       }//if 1            
   }//testLeadCampaignScoreInitialize 

     public static testMethod void testLeadScoringSetupController() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.LeadScoringSetup;
        cleanUpTestData();
        test.startTest();
        Test.setCurrentPage(pageRef);
        LeadScoringBatchInitialize ctr = new LeadScoringBatchInitialize();

        ctr.autorun();
        test.stopTest();
   }//testLeadScoringSetupController        
   
   static testMethod void verifyLongRuleNameDoesntBreak(){
        Long numLeads=1;
        List<Lead> leads = new List<lead>();
        Boolean Active=True;
        
        Double LSRScore=1;
        String LSRType='Lead';
        String LSRFieldName='LeadSource';
        String LSROperator='Does Not Contain';
        String LSRValue='123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';

        List<LeadScoringRule__c> lsrs=new List<LeadScoringRule__c>();
        
        cleanUpTestData();
        
        lsrs.add(createLSR(Active, LSRType , LSRScore, LSRFieldName, LSROperator, LSRValue));    
        //test is that this doesn't gack:
        insert lsrs;
        
    }//verifyLongRuleNameDoesntBreak

   
    
}//LeadScoringTests