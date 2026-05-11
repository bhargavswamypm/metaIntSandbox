@isTest
public class InvoicePdfControllerTest {
@isTest
    static void testInvoicePdfController() {
        // Create test data
        Account testAccount = new Account(Name='Test Account', BillingStreet='123 Main St', BillingCity='City', BillingState='State', BillingPostalCode='12345', BillingCountry='Country');
        insert testAccount;

        Contact testContact = new Contact(AccountId=testAccount.Id, FirstName='Test', LastName='Contact');
        insert testContact;
        
         Employees__c Emp = new Employees__c();
        Emp.Employee_ID__c= 'ZT10325';
        Emp.Name ='Dhanush Kumar';
        Emp.Cost__c=100;
        Emp.Business_Unit__c='Salesforce';
        insert Emp;
        
        Employees__c Emp1 = new Employees__c();
        Emp1.Employee_ID__c= 'ZT10982';
        Emp1.Name ='Dhanush Kumar 2';
        Emp1.Cost__c=0;
        Emp1.Business_Unit__c='Salesforce';
        insert Emp1;
        
         Opportunity Opp = new Opportunity();
        opp.Amount=10000;
        opp.HSN_SAC1__c='12345';
        opp.Name = 'Dhanush kumar';
        opp.Night_Shift_Expense__c = 200;
        opp.Month1__c='January';
        opp.Years__c='2024';
        opp.US_Call_Expense__c = 300;
        opp.PST_Shift_Expense__c = 400;
        opp.ForecastCategoryName='Pipeline';
        opp.CloseDate=System.today();
        opp.StageName = 'Proposal';
        opp.AccountId=testAccount.Id;
        opp.ContactId = testContact.Id;
        opp.Business_Location__c='Domestic';
        insert opp;
         OpportunityEmployees__c Ope = new OpportunityEmployees__c();
        Ope.Employee__c= Emp.Id;
           Ope.Cost__c = 100;
            Ope.Night_Shift__c = 1;
            Ope.PST_Shift__c = 2;
            Ope.US_Call__c = 3;
            Ope.Weekend__c = 4;
            Ope.Opportunity__c = opp.Id;
        insert Ope;
        
        
            Invoice__c testInvoice = new Invoice__c();
            testInvoice.Opportunity__c=opp.Id;
            testInvoice.Business_Location__c=opp.Business_Location__c;
            testInvoice.Invoice_Date__c=Date.today();
            
            testInvoice.HSN_SAC1__c='12345';
            testInvoice.Night_Shift_Expense__c=opp.Night_Shift_Expense__c;
            testInvoice.PST_Shift_Expense__c=opp.PST_Shift_Expense__c;
            testInvoice.US_Call_Expense__c=opp.US_Call_Expense__c;
            testInvoice.Business_Location__c=opp.Business_Location__c;
            testInvoice.UniqueId__c ='Dhanu';
        insert testInvoice;
        system.debug(testInvoice.PST_Shift_Expense__c);
        InvoiceLineItems__c testInvoiceLineItem = new InvoiceLineItems__c();
        testInvoiceLineItem.InvoiceId__c=testInvoice.Id;
        testInvoiceLineItem.No_Working_Days__c = 0;
        testInvoiceLineItem.Cost__c = 0;
        testInvoiceLineItem.Employee__c = Emp.id;
        insert testInvoiceLineItem;
        
        InvoiceLineItems__c testInvoiceLineItem1 = new InvoiceLineItems__c();
        testInvoiceLineItem1.InvoiceId__c=testInvoice.Id;
        testInvoiceLineItem1.No_Working_Days__c = 25;
        testInvoiceLineItem1.Employee__c = Emp1.id;
        insert testInvoiceLineItem1;

        // Set up page parameters
        PageReference pageRef = Page.ZucitechInvoicePDF; // Replace 'YourPageName' with the actual name of your Visualforce page
        Test.setCurrentPageReference(pageRef);
        ApexPages.currentPage().getParameters().put('id', testInvoice.Id);

       
        InvoicePdfController controller = new InvoicePdfController(new ApexPages.StandardController(testInvoice));

        
        System.assertEquals(testInvoice.Id, controller.id);
        System.assertEquals(testInvoice.Opportunity__c, controller.opportunity.Id); 

        
        Test.startTest();
        controller.generatePDF();
        Test.stopTest();

        // Verify that an attachment is created
        List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :testInvoice.Id];
        System.assertNotEquals(0, attachments.size());
    }
}