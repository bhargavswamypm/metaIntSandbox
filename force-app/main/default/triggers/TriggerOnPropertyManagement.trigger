trigger TriggerOnPropertyManagement on Property_Management__c (after insert,after update) {

    if(Trigger.isAfter){
        PropertyManagementHandler.syncServices(Trigger.new,Trigger.oldMap);
    }

}