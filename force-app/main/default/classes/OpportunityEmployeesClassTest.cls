@isTest
public class OpportunityEmployeesClassTest {
    @isTest
    static void AfterDeletionTest (){
        
            Decimal TotalOpp = 0.00;
            Decimal TotalPh = 0.00;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity(Name = 'Test Opportunity 2000', StageName = 'Prospecting', CloseDate = Date.today(), AccountId = acc.Id,
        ForecastCategoryName= 'Pipeline',Business_Location__c='Domestic',Amount=10,HSN_SAC1__c='123456',Month1__c='January',
        Years__c='2024',Night_Shift_Expense__c=10,PST_Shift_Expense__c=19,US_Call_Expense__c=29);
        insert opp;
        
        Project_History__c projectHistory = new Project_History__c(Name = 'Test Project History',Taxation__c='Domestic',Amount__c=10,HSN_SAC__c='123456',Month__c='January',
        Years__c='2024',Night_Shift_Expense__c=10,PST_Shift_Expense__c=19,US_Call_Expense__c=29,Opportunity__c=opp.Id);
        insert projectHistory;
        
        Invoice__c inv1 = new Invoice__c( Opportunity__c = opp.Id,US_Call_Expense__c=10,Night_Shift_Expense__c=10,PST_Shift_Expense__c=19,
        Business_Location__c='Domestic',HSN_SAC1__c='123455',UniqueId__c = 'UID123', Project_History__c = projectHistory.Id, Number_Assoc_with_ID__c = 011,start_date__c=system.today());
        //Invoice__c inv2 = new Invoice__c( Opportunity__c = opp.Id, UniqueId__c = 'UID124', Project_History__c = projectHistory.Id);
        insert inv1;
        
        Invoice__c inv2 = new Invoice__c(US_Call_Expense__c=10,Night_Shift_Expense__c=10,PST_Shift_Expense__c=19,
        Business_Location__c='Domestic',HSN_SAC1__c='123455',UniqueId__c = 'UID124', Project_History__c = projectHistory.Id, Number_Assoc_with_ID__c = 012,start_date__c=system.today());
        //Invoice__c inv2 = new Invoice__c( Opportunity__c = opp.Id, UniqueId__c = 'UID124', Project_History__c = projectHistory.Id);
        insert inv2;
        //insert inv2;
        
        Employees__c emp = new Employees__c(Name='Bhargav', business_unit__c='Salesforce',cost__c=200.00,employee_id__c='ZT10276');
        insert emp;
        
        OpportunityEmployees__c Ope = new OpportunityEmployees__c();
            Ope.Employee__c= Emp.Id;
            Ope.Cost__c = 100;
            Ope.Night_Shift__c = 1;
            Ope.PST_Shift__c = 2;
            Ope.US_Call__c = 3;
            Ope.Weekend__c = 4;
            Ope.Opportunity__c = opp.Id;
            List<OpportunityEmployees__c> OpeList = new List<OpportunityEmployees__c>();
            OpeList.add(ope);
            //insert OpeList;
        
                OpportunityEmployees__c Ope1 = new OpportunityEmployees__c();
            Ope1.Employee__c= Emp.Id;
            Ope1.Cost__c = 100;
            Ope1.Night_Shift__c = 1;
            Ope1.PST_Shift__c = 2;
            Ope1.US_Call__c = 3;
            Ope1.Weekend__c = 4;
            Ope1.Project_History__c = projectHistory.id;
            List<OpportunityEmployees__c> OpeList1 = new List<OpportunityEmployees__c>();
            OpeList.add(ope1);
            //insert OpeList1;
        
/*            Test.startTest();
            OpportunityEmployeesClass.AfterDeletion(OpeList);
            OpportunityEmployeesClass.AfterDeletion(OpeList1);
            Test.stopTest(); */
            Test.startTest();
    insert OpeList;
    insert OpeList1;

    // Capture the initial values
    Opportunity oppBefore = [SELECT Id, Present_Cycle_Expense__c FROM Opportunity WHERE Id = :opp.Id];
    Project_History__c phBefore = [SELECT Id, Present_Cycle_Expense__c FROM Project_History__c WHERE Id = :projectHistory.Id];

    // Delete the records
    delete OpeList;
    delete OpeList1;
    Test.stopTest();

    // Query the records again to check for updates
    Opportunity oppAfter = [SELECT Id, Present_Cycle_Expense__c FROM Opportunity WHERE Id = :opp.Id];
    Project_History__c phAfter = [SELECT Id, Present_Cycle_Expense__c FROM Project_History__c WHERE Id = :projectHistory.Id];

    // Assert the changes
    System.assertNotEquals(oppBefore.Present_Cycle_Expense__c, oppAfter.Present_Cycle_Expense__c, 'Opportunity Present_Cycle_Expense__c should have changed');
    System.assertNotEquals(phBefore.Present_Cycle_Expense__c, phAfter.Present_Cycle_Expense__c, 'Project_History__c Present_Cycle_Expense__c should have changed');
    }
}