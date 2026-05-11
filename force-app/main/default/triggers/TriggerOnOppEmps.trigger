trigger TriggerOnOppEmps on OpportunityEmployees__c (after delete) {

    if(Trigger.IsAfter && Trigger.IsDelete){
    OpportunityEmployeesClass.AfterDeletion (Trigger.old);
    }
    
}