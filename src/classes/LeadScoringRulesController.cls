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
public with sharing class LeadScoringRulesController {
    
    public Boolean picklistRendered { get; set;}
    public Boolean inputBoxRendered{ get; set; }
    public Boolean inputCheckBoxRendered{ get; set;}
    
    private LeadScoringRule__c lsr;

    private ApexPages.StandardController lsrController;
    
    public LeadScoringRulesController(ApexPages.StandardController controller) {
        lsrController = controller;
        lsr= (LeadScoringRule__c)controller.getRecord();
        valueRender();       
    }
  
    public PageReference saveNew()
    {
        PageReference pr;
        try{
            //lsrController.save(); //Note save breaks for some reason but upsert works
            upsert lsr;
            Schema.DescribeSObjectResult describeResult = lsrController.getRecord().getSObjectType().getDescribe();
            pr = new PageReference('/' + describeResult.getKeyPrefix() + '/e');
            pr.setRedirect(true);
            return pr;    
        }catch(Exception e){
            system.debug('Save & New failed, likely due to validation rule errors or trigger fail due to bad data or null field, value or operator. Error: '+e);
//            ApexPages.addmessages(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
            ApexPages.addmessages(e);            
            return null;
        }//try

    }//saveNew
        
    public List<selectOption> getLSROperator(){
       List<selectOption> options=new List<selectOption>();
       Map<String, Schema.SObjectField> cmFieldMap=Schema.SObjectType.CampaignMember.fields.getMap();
       Map<String, Schema.SObjectField> leadFieldMap=Schema.SObjectType.Lead.fields.getMap();
       DisplayType fieldType;
       Boolean typeSelected=False;
        
       if (lsr.Type__c=='Lead'){//if 1
           Schema.SObjectField fieldToken=leadFieldMap.get(lsr.Field_Name__c);
            try{
               fieldType=fieldToken.getDescribe().getType();
               typeSelected=true;
            }catch (Exception e){}//exception happens when changing type as the other picklist hasn't had a chance to refresh yet   
       } else if (lsr.Type__c=='Campaign Member'){
           Schema.SObjectField fieldToken=cmFieldMap.get(lsr.Field_Name__c);
           try{
               fieldType=fieldToken.getDescribe().getType();
               typeSelected=true;
           }catch (Exception e){}//exception happens when changing type as the other picklist hasn't had a chance to refresh yet
       } else {
           typeSelected=False;
       }//if 1
        
       //only add an operator if a valid field type is chosen.  Otherwise, leave it blank.
       if (typeSelected){//if 1
           if (fieldType!=Schema.DisplayType.anyType && fieldType!=Schema.DisplayType.base64 && fieldType!=Schema.DisplayType.Date && fieldType!=Schema.DisplayType.DateTime && fieldType!=Schema.DisplayType.EncryptedString && fieldType!=Schema.DisplayType.Id && fieldType!=Schema.DisplayType.MultiPicklist&&fieldType!=Schema.DisplayType.Reference&&fieldType!=Schema.DisplayType.TextArea && fieldType!=Schema.DisplayType.Time){//if 2
               //the above types are unsupported at this time 
               options.add(new selectOption('equals','equals')); 
               options.add(new selectOption('not equal to','not equal to')); 
               if (fieldType!=Schema.DisplayType.Boolean&&fieldType!=Schema.DisplayType.Picklist){//if 3
                   //boolean can't use the below, but the others can
                   options.add(new selectOption('greater than','greater than')); 
                   options.add(new selectOption('less than','less than')); 
                   options.add(new selectOption('greater or equal','greater or equal')); 
                   options.add(new selectOption('less or equal','less or equal')); 
                   if (fieldType==Schema.DisplayType.STRING || fieldType==Schema.DisplayType.ComboBox ||fieldType==Schema.DisplayType.Picklist ||fieldType==Schema.DisplayType.email||fieldType==Schema.DisplayType.encryptedString||fieldType==Schema.DisplayType.Phone||fieldType==Schema.DisplayType.url){//if 4
                       //these options are for string type fields
                       options.add(new selectOption('contains','contains')); 
                       options.add(new selectOption('does not contain','does not contain')); 
                       options.add(new selectOption('starts with','starts with')); 
                   }//if 4
              }//if 3
          }//if 2          
       }//if 1
       return options;
    }
    
    public List<selectOption> getLSRFieldNames(){
        List<selectOption> options=new List<selectOption>();
        List<String> fieldLabels=new List<String>();//included to create a sorted field name list
        Map<String,String> fieldLabelNameMap=new Map<String,String>();
        Map<String, Schema.SObjectField> fieldMap=new Map<String, Schema.SObjectField>();

        Boolean evaluateFields=false;
        
        if(lsr.Type__c=='Campaign Member'){
            fieldMap=Schema.SObjectType.CampaignMember.fields.getMap();
            evaluateFields=true;
        } else if(lsr.Type__c=='Lead'){
            fieldMap=Schema.SObjectType.Lead.fields.getMap();
            evaluateFields=true;
        }
        
        if (evaluateFields){//if 1    
            options.add(new selectOption('',''));
            
            for (String fName:fieldMap.keySet()){//for 1
                //Disallow unsupported field types
                if(fieldMap.get(fName).getDescribe().getType()!=Schema.DisplayType.anytype&&fieldMap.get(fName).getDescribe().getType()!=Schema.DisplayType.base64&&fieldMap.get(fName).getDescribe().getType()!=Schema.DisplayType.Date&&fieldMap.get(fName).getDescribe().getType()!=Schema.DisplayType.DateTime&&fieldMap.get(fName).getDescribe().getType()!=Schema.DisplayType.EncryptedString&&fieldMap.get(fName).getDescribe().getType()!=Schema.DisplayType.Id&&fieldMap.get(fName).getDescribe().getType()!=Schema.DisplayType.MultiPicklist&&fieldMap.get(fName).getDescribe().getType()!=Schema.DisplayType.Reference&&fieldMap.get(fName).getDescribe().getType()!=Schema.DisplayType.TextArea&&fieldMap.get(fName).getDescribe().getType()!=Schema.DisplayType.Time){
                    fieldLabels.add(fieldMap.get(fName).getDescribe().getLabel());                  
                    fieldLabelNameMap.put(fieldMap.get(fName).getDescribe().getLabel(), fName);
                }//if 2
            }//for 1
            fieldLabels.sort();
            for (String fLabel:fieldLabels){//for 1
                //Remove the package fields Lead Score, Campaign Score, and Total Score, to avoid a query issue.
                if((fieldLabelNameMap.get(fLabel)!='Lead_Score__c')&&(fieldLabelNameMap.get(fLabel)!='Campaign_Score__c')&&(fieldLabelNameMap.get(fLabel)!='Total_Score__c')){//if 2
                    options.add(new selectOption(fieldLabelNameMap.get(fLabel),fLabel));
                }//if 2
            }//for 1    
        }//if 1

        return options;
    }//getLSRFieldNames
    
    public List<SelectOption> getValuePicklistOptions(){
        List<SelectOption> valuePicklistOptions = new List<SelectOption>();
        Map<String, Schema.SObjectField> fieldMap=new Map<String, Schema.SObjectField>();
        if (lsr.Field_Name__c!=null){
            String fName=lsr.Field_Name__c;
            system.debug('Field Name: '+fName);
            if(lsr.Type__c=='Campaign Member'){
                fieldMap=Schema.SObjectType.CampaignMember.fields.getMap();
            } else if(lsr.Type__c=='Lead'){
                fieldMap=Schema.SObjectType.Lead.fields.getMap();
            }
            try{//this will error when changing types as the field name is different than the type as the FieldNames picklsit hasn't been regenerated yet
                Schema.DisplayType fType=fieldMap.get(fName).getDescribe().getType();
                if(fType==Schema.DisplayType.Picklist){
                    for (Schema.PickListEntry pickVal: fieldMap.get(fName).getDescribe().getPicklistValues()){
                        // create a selectoption for each pickval
                        valuePicklistOptions.add(new SelectOption(pickVal.getValue(),pickVal.getLabel()));
                    }//for 1
                }//if 2
            }catch(Exception e){
                system.debug('getValuePicklistOptions had an error, likely due to switching between Lead & Campaign Member rules. Error:'+e);
            }
        }//if 1    
        return valuePicklistOptions ;
    } //getValuePicklistOptions
    
    public void valueRender(){
        picklistRendered=False;
        inputCheckBoxRendered=False;
        Map<String, Schema.SObjectField> fieldMap=new Map<String, Schema.SObjectField>();
        if (lsr.Field_Name__c!=null &&lsr.Type__c!=null){//if 1
            String fname=lsr.Field_Name__c;

            if(lsr.Type__c=='Campaign Member'){//if 2
                fieldMap=Schema.SObjectType.CampaignMember.fields.getMap();
            } else if(lsr.Type__c=='Lead'){
                fieldMap=Schema.SObjectType.Lead.fields.getMap();
            }//if 2
            if(fieldMap.get(fName).getDescribe().getType()==Schema.DisplayType.Picklist){//if 2
                picklistRendered=True;
            }else if(fieldMap.get(fName).getDescribe().getType()==Schema.DisplayType.Boolean){
                inputCheckBoxRendered=True;
            }//if 2    
        }//if 1
        inputboxRendered=!(picklistRendered || inputCheckBoxRendered);
    }//picklsitRendered    

}