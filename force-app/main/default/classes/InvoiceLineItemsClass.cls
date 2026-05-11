public class InvoiceLineItemsClass {

    public static void BeforeInsertion (List<Invoicelineitems__c> InvList){
        if(!InvList.isEmpty()){
            for(Invoicelineitems__c inv : InvList){
                //inv.Cost__c = inv.Salary__c;
                if(inv.Created_By_Project_History__c == false){
                inv.No_Working_Days__c = inv.Selected_Days__c;
            	}
            }
        }
    }
    
    public static void BeforeUpdation (List<Invoicelineitems__c> InvList){
        if(!InvList.isEmpty()){
            for(Invoicelineitems__c inv : InvList){
                inv.Cost__c = inv.Salary__c;
                if(inv.No_Working_Days__c > inv.Selected_Days__c){
                    inv.addError('Number of working days cannot exceed days in the month');
                }
                if(inv.No_Working_Days__c == null){
                    inv.No_Working_Days__c = 0;
                }
                if(inv.No_Working_Days__c < inv.Selected_Days__c){
                   inv.Less_Working_Days__c = true; 
                }
                if(inv.No_Working_Days__c == inv.Selected_Days__c){
                   inv.Less_Working_Days__c = false; 
                }
            }
        }
    }
}