trigger EventTrigger on Event (after insert, after update, after delete) {
    if (Trigger.isInsert || Trigger.isUpdate) {
        EventTriggerHandler.updateCustomLeadSiteVisit(Trigger.new, Trigger.isDelete);
    }
    if (Trigger.isDelete) {
        EventTriggerHandler.updateCustomLeadSiteVisit(Trigger.old, true);
    }
}