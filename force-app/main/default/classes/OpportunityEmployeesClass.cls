public class OpportunityEmployeesClass {

    public static void AfterDeletion(List<OpportunityEmployees__c> OppEmpList){
        if(!OppEmpList.isempty()){
            Set<id> delListOpp = new Set<id>();
            Set<id> delListPH = new Set<id>();
            
            String oppId = '';
            String phId = '';
            for(OpportunityEmployees__c ope : OppEmpList){
                if(ope.Opportunity__c != null){
                    delListOpp.add(ope.Id);
                    oppId = ope.Opportunity__c;
                }
                if(ope.Project_History__c != null){
                    delListPH.add(ope.id);
                    phId = ope.Project_History__c;
                }
             }
            System.debug('Present opp emp Id: '+delListPH);
            System.debug('PH Id :'+phId);
            List<OpportunityEmployees__c> oeList = [Select id,Total_Cost__c,Opportunity__c,Project_History__c from OpportunityEmployees__c where Opportunity__c =: oppId AND Project_History__c = null AND Id NOT IN:delListOpp ];

            List<OpportunityEmployees__c> oePhList = [Select id,Total_Cost__c,Opportunity__c,Project_History__c from OpportunityEmployees__c where Project_History__c =: phId AND Id NOT IN:delListPH ];            
            
            System.debug('List of oePhList' +oePhList);
            
            Decimal TotalOpp = 0.00;
            Decimal TotalPh = 0.00;
            
            for(OpportunityEmployees__c ope : oeList){
                if(ope.Total_Cost__c != null){//Opportunity employee Calc for Opportunity Object
                if(TotalOpp == 0.00){
                    TotalOpp = ope.Total_Cost__c;
                }
                else{
                    TotalOpp = TotalOpp + ope.Total_Cost__c;  
                }
                }
            }
            System.debug('OeList Executed');
            for(OpportunityEmployees__c ope : oePhList){
                //Opportunity employee Calc for Project History Object
                if(ope.Total_Cost__c != null){
                if(TotalPh == 0.00){
                TotalPh = ope.Total_Cost__c;
                }
                else{
                TotalPh = TotalPh + ope.Total_Cost__c;
                }
                }
            }
            
            System.debug('TotalPh'+TotalPh);
            
            for(OpportunityEmployees__c ope : OppEmpList){
                if(ope.Project_History__c == null){
                    Opportunity opp = new Opportunity();
                    opp.Id = ope.Opportunity__c;
                    opp.Present_Cycle_Expense__c = TotalOpp;
                    Update opp;
                }
                else if(ope.Project_History__c == phID){
                    Project_History__c ph = new Project_History__c();
                    ph.Id = ope.Project_History__c;
                    ph.Present_Cycle_Expense__c = TotalPh;
                    Update ph;
                    System.debug(ph);
                } 
            }
        }
    }
}