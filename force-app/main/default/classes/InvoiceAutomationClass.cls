public class InvoiceAutomationClass {

    public static void BeforeInsertion (List<Invoice__c> InvList){
        if(!InvList.isEmpty()){
            String invFY ='';
            for(Invoice__c inv : InvList){
                invFY = inv.FY__c;
            }

            List<Invoice__c> Invoice = [Select id,FY__c,Number_Assoc_with_ID__c from Invoice__c where FY__c =: invFY AND Number_Assoc_with_ID__c != null ORDER BY Number_assoc_with_id__c DESC LIMIT 1];
                Decimal NumberAssoc = 0;
                if(Invoice.size() > 0){
                	for(Invoice__c inv : Invoice){
                    	NumberAssoc = inv.Number_Assoc_with_ID__c;
                	}
                }

              for(Invoice__c inv : InvList){
                if(NumberAssoc == 0){
                    inv.Number_Assoc_with_ID__c = 001;
                }
                else if(NumberAssoc > 0){
                    inv.Number_Assoc_with_ID__c = NumberAssoc+1;
                }
            }
        }
    }
    
    public static void AfterInsertion (List<Invoice__c> InvList){
        
    }
    
    public static void AfterDeletion (List<Invoice__c> InvList){
        Set<Id> invId = new  Set<Id>();
        if(!InvList.isEmpty()){
        for(Invoice__c inv : InvList){
            if(inv.Opportunity__c != null && inv.UniqueId__c != null && inv.Project_History__c != null){
                invId.add(inv.Project_History__c);
            }
        }
            //new Project_History__c(id = inv.Project_History__c,	Opportunity__c = inv.Opportunity__c);
            List<Project_History__c> PH = [Select Id from Project_History__c where Id IN: invId ];
                if(PH.size() > 0){
                delete PH;
                }       
             
   		 }
    }
}