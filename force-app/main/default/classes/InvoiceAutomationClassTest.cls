@isTest
public class InvoiceAutomationClassTest {
    
    @testSetup
    static void setup() {
        // Create sample data for test
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity(Name = 'Test Opportunity 2000', StageName = 'Prospecting', CloseDate = Date.today(), AccountId = acc.Id,
     	ForecastCategoryName= 'Pipeline',Business_Location__c='Domestic',Amount=10,HSN_SAC1__c='123456',Month1__c='January',
       	Years__c='2024',Night_Shift_Expense__c=10,PST_Shift_Expense__c=19,US_Call_Expense__c=29);
        insert opp;
        
        Project_History__c projectHistory = new Project_History__c(Name = 'Test Project History',Taxation__c='Domestic',Amount__c=10,HSN_SAC__c='123456',Month__c='January',
       	Years__c='2024',Night_Shift_Expense__c=10,PST_Shift_Expense__c=19,US_Call_Expense__c=29,Opportunity__c=opp.Id);
        insert projectHistory;
        
        Invoice__c inv1 = new Invoice__c( Opportunity__c = opp.Id,US_Call_Expense__c=10,Night_Shift_Expense__c=10,PST_Shift_Expense__c=19,PO_Number__c='101011',
   		Business_Location__c='Domestic',HSN_SAC1__c='123455',UniqueId__c = 'UID123', Project_History__c = projectHistory.Id,start_date__c=system.today());
        //Invoice__c inv2 = new Invoice__c( Opportunity__c = opp.Id, UniqueId__c = 'UID124', Project_History__c = projectHistory.Id);
        insert inv1;
        
        /*Invoice__c inv2 = new Invoice__c( Opportunity__c = opp.Id,US_Call_Expense__c=10,Night_Shift_Expense__c=10,PST_Shift_Expense__c=19,PO_Number__c='101011',
   		Business_Location__c='Domestic',HSN_SAC1__c='123455',UniqueId__c = 'UID124', Project_History__c = projectHistory.Id,start_date__c=system.today());
        //Invoice__c inv2 = new Invoice__c( Opportunity__c = opp.Id, UniqueId__c = 'UID124', Project_History__c = projectHistory.Id);
        insert inv2; */

        //insert inv2;
    }
    
        @isTest
    static void testBeforeInsertion() {
        // Query the Invoices created in test setup
	Opportunity opp = [Select id from opportunity where name = 'Test Opportunity 2000'];
	List<Invoice__c> invoices = [Select id,Opportunity__c,FY__c,UniqueId__c,US_Call_Expense__c,Night_Shift_Expense__c,PST_Shift_Expense__c,PO_Number__c,
   	Business_Location__c,HSN_SAC1__c, Project_History__c, start_date__c from invoice__c where Opportunity__c =: opp.Id];
        
        Test.startTest();
        InvoiceAutomationClass.BeforeInsertion(invoices);
        Test.stopTest();
        
    }
    
    @isTest
    static void testAfterDeletion() {
	Opportunity opp = [Select id from opportunity where name = 'Test Opportunity 2000'];
	List<Invoice__c> invoices = [Select id,Opportunity__c,FY__c,UniqueId__c,US_Call_Expense__c,Night_Shift_Expense__c,PST_Shift_Expense__c,PO_Number__c,
   	Business_Location__c,HSN_SAC1__c, Project_History__c, start_date__c from invoice__c where Opportunity__c =: opp.Id];
        
        // Delete the invoices
        delete invoices;
        
        // Call the AfterDeletion method
        Test.startTest();
        InvoiceAutomationClass.AfterDeletion(invoices);
        Test.stopTest();
        
        
        // Verify that related Project_History__c records are deleted
        List<Project_History__c> projectHistories = [SELECT Id FROM Project_History__c];
        System.assertEquals(0, projectHistories.size(), 'Related Project_History__c records should be deleted');
    }
}