@isTest
public class InvoiceLineItemsClassTest {
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
        
        Invoice__c inv1 = new Invoice__c( Opportunity__c = opp.Id,US_Call_Expense__c=10,Night_Shift_Expense__c=10,PST_Shift_Expense__c=19,
        Business_Location__c='Domestic',HSN_SAC1__c='123455',UniqueId__c = 'UID123', Project_History__c = projectHistory.Id, Number_Assoc_with_ID__c = 011,start_date__c=system.today(), End_Date__c = system.today());
        //Invoice__c inv2 = new Invoice__c( Opportunity__c = opp.Id, UniqueId__c = 'UID124', Project_History__c = projectHistory.Id);
        insert inv1;
        //insert inv2;
        
        Employees__c emp = new Employees__c(Name='Bhargav', business_unit__c='Salesforce',cost__c=200.00,employee_id__c='ZT10276');         
    }
    
    @isTest
    static void BeforeInsertionTest(){
        
    Opportunity opp = [Select id from opportunity where name = 'Test Opportunity 2000'];
    Invoice__c inv = [Select id from invoice__c where Opportunity__c =: opp.Id];
    Employees__c emp = new Employees__c(Name='Bhargav', business_unit__c='Salesforce',cost__c=200.00,employee_id__c='ZT10276');
    insert emp;
    Invoicelineitems__c invline = new Invoicelineitems__c(Invoiceid__c=inv.id,Employee__c=emp.id,Less_Working_Days__c=false);
    List<Invoicelineitems__c> newList = new List<Invoicelineitems__c>();
    newList.add(invline);
    if(newList.size() > 0){
    insert newList;
    }
    /*List<Invoicelineitems__c> newList1 = new List<Invoicelineitems__c>();
    invline.No_Working_Days__c = 45;
    newList1.add(invline);
    if(newList1.size() > 0){
    update newList1;
    }*/
    List<Invoicelineitems__c> newList2 = new List<Invoicelineitems__c>();
    invline.No_Working_Days__c = 0;
    newList2.add(invline);
    if(newList2.size() > 0){
    update newList2;
    }
    List<Invoicelineitems__c> newList3 = new List<Invoicelineitems__c>();
    invline.No_Working_Days__c = null;
    newList3.add(invline);
    if(newList2.size() > 0){
    update newList3;
    }        
    }   
    
}