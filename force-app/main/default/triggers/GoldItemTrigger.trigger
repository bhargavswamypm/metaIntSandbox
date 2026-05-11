trigger GoldItemTrigger on Gold_Item__c ( after insert,after update,after delete,after undelete) {
    
    Set<Id> opportunityIds = new Set<Id>();

    // Collect Opportunity Ids
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (Gold_Item__c item : Trigger.new) {
            if (item.Opportunity__c != null) {
                opportunityIds.add(item.Opportunity__c);
            }
        }
    }

    if (Trigger.isDelete) {
        for (Gold_Item__c item : Trigger.old) {
            if (item.Opportunity__c != null) {
                opportunityIds.add(item.Opportunity__c);
            }
        }
    }

    if (opportunityIds.isEmpty()) {
        return;
    }

    // Aggregate Gold Item weights
    Map<Id, AggregateResult> oppTotals = new Map<Id, AggregateResult>();

    for (AggregateResult ar : [
        SELECT
            Opportunity__c oppId,
            SUM(GrossWeight__c) totalGross,
            SUM(NetWeight__c) totalNet
        FROM Gold_Item__c
        WHERE Opportunity__c IN :opportunityIds
        GROUP BY Opportunity__c
    ]) {
        oppTotals.put((Id) ar.get('oppId'), ar);
    }

    // Prepare Opportunity updates
    List<Opportunity> oppsToUpdate = new List<Opportunity>();

    for (Id oppId : opportunityIds) {
        AggregateResult ar = oppTotals.get(oppId);

        Opportunity opp = new Opportunity(
            Id = oppId,
            Final_Gross_Weight__c = ar != null ? (Decimal) ar.get('totalGross') : 0,
            Final_Net_Weight__c  = ar != null ? (Decimal) ar.get('totalNet') : 0
        );

        oppsToUpdate.add(opp);
    }

    if (!oppsToUpdate.isEmpty()) {
        update oppsToUpdate;
    }

}