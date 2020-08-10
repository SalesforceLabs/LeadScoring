trigger createLSRLabelAndName on LeadScoringRule__c(
    before insert,
    before update
) {
    //This simple trigger creates a name for the lead scoring rule automatically so that customers don't have to type it themselves
    //Also, this converts field names to lowercase as Apex Set() considers "email" and "Email" to be 2 different entries
    Map<String, Schema.SObjectField> leadFieldMap = Schema.SObjectType.Lead.fields.getMap();
    Map<String, Schema.SObjectField> cmFieldMap = Schema.SObjectType.CampaignMember.fields.getMap();

    for (LeadScoringRule__c lsr : Trigger.new) {
        if (lsr.Field_Name__c != null) {
            //if 1
            if (lsr.Type__c == 'Lead') {
                //if 2
                try {
                    lsr.Field_Label__c = leadFieldMap.get(lsr.Field_Name__c)
                        .getDescribe()
                        .getLabel();
                } catch (Exception e) {
                    system.debug(
                        'Field name is likely invalid for lead.  Field Name: ' +
                        lsr.Field_Name__c +
                        '.  Error: ' +
                        e
                    );
                    lsr.adderror(
                        'Error: Invalid Lead field name entered: ' +
                        lsr.Field_Name__c +
                        '.  Please enter a valid field name.'
                    );
                }
            } else if (lsr.Type__c == 'Campaign Member') {
                try {
                    lsr.Field_Label__c = cmFieldMap.get(lsr.Field_Name__c)
                        .getDescribe()
                        .getLabel();
                } catch (Exception e) {
                    system.debug(
                        'Field name is likely invalid for campaign member. Field Name: ' +
                        lsr.Field_Name__c +
                        '.  Error: ' +
                        e
                    );
                    lsr.adderror(
                        'Error: Invalid Campaign Member field name entered: ' +
                        lsr.Field_Name__c +
                        '.  Please enter a valid field name.'
                    );
                }
            } //if 2
            String ruleName =
                lsr.Type__c +
                ' ' +
                lsr.Field_Label__c +
                ' ' +
                lsr.Operator__c +
                ' ' +
                lsr.Value__c;
            if (ruleName.length() >= 80) {
                ruleName = ruleName.substring(0, 79);
            }
            lsr.name = ruleName;
            if (lsr.Field_Name__c != null) {
                //if 1
                lsr.Field_Name__c = lsr.Field_Name__c.toLowerCase();
            } //if 2
        } //if 1
    } //for

}
