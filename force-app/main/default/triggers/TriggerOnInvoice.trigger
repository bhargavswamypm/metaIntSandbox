trigger TriggerOnInvoice on Invoice__c (before insert, after delete) {

    if(Trigger.IsInsert && Trigger.IsBefore){
        InvoiceAutomationClass.BeforeInsertion(trigger.new);
    }
    
    if(Trigger.IsDelete && Trigger.IsAfter){
        InvoiceAutomationClass.AfterDeletion(trigger.old);
    }
    
}