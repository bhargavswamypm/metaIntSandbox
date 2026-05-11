trigger TriggerOnInvoiceLineItems on Invoicelineitems__c (before insert, before update) {
    
    if(Trigger.IsInsert && Trigger.IsBefore){
        InvoiceLineItemsClass.BeforeInsertion(Trigger.new);
    }

    if(Trigger.IsUpdate && Trigger.IsBefore){
        InvoiceLineItemsClass.BeforeUpdation(Trigger.new);
    }
}