trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert, after delete) {

    Set<Id> checklistIds = new Set<Id>();

    // Get Document_CheckList__c object prefix dynamically
    String checklistPrefix =
        Document_CheckList__c.SObjectType.getDescribe().getKeyPrefix();

    if (Trigger.isInsert) {
        for (ContentDocumentLink cdl : Trigger.new) {
            if (cdl.LinkedEntityId != null &&
                String.valueOf(cdl.LinkedEntityId).startsWith(checklistPrefix)) {
                checklistIds.add(cdl.LinkedEntityId);
            }
        }
    }

    if (Trigger.isDelete) {
        for (ContentDocumentLink cdl : Trigger.old) {
            if (cdl.LinkedEntityId != null &&
                String.valueOf(cdl.LinkedEntityId).startsWith(checklistPrefix)) {
                checklistIds.add(cdl.LinkedEntityId);
            }
        }
    }

    if (!checklistIds.isEmpty()) {
        FileCountHandler.updateChecklistFileCount(checklistIds);
    }
}