public class LeadScoringBatchInitialize{

    // Constructor - this only really matters if the autoRun function doesn't work right
    public LeadScoringBatchInitialize() {
    }
    // Code we will invoke on button click.
    public void autoRun() {
        //First invoke the lead initialization.  
        LeadScoringInitialize initLeads= new LeadScoringInitialize  ();
        initLeads.leadQuery = 'Select Id FROM Lead WHERE IsConverted= FALSE';
        Id leadProcessId = Database.executeBatch(initLeads); 

        //Then invoke the campaign member updates
        LeadCampaignScoreInitialize initCMs= new LeadCampaignScoreInitialize ();
        initCMs.cmQuery = 'Select Id FROM CampaignMember WHERE ContactID = null';
        Id cmProcessId = Database.executeBatch(initCMs, 100); 
    }
}