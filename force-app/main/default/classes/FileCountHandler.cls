public class FileCountHandler {

    public static void updateChecklistFileCount(Set<Id> checklistIds) {

        Map<Id, Integer> fileCountMap = new Map<Id, Integer>();

        for (AggregateResult ar : [
            SELECT LinkedEntityId entityId, COUNT(Id) fileCount
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :checklistIds
            GROUP BY LinkedEntityId
        ]) {
            fileCountMap.put(
                (Id) ar.get('entityId'),
                (Integer) ar.get('fileCount')
            );
        }

        List<Document_CheckList__c> updates =
            new List<Document_CheckList__c>();

        for (Id checklistId : checklistIds) {
            Integer count = fileCountMap.containsKey(checklistId)
                ? fileCountMap.get(checklistId)
                : 0;

            updates.add(new Document_CheckList__c(
                Id = checklistId,
                File_Count__c = count,
                Uploaded__c = (count > 0)
            ));
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }
}