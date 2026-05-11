@isTest
public class EmployeeNotworkingForMonthSchedulerTest {
		    @istest 
    public static void setup() {
       // Employees__c emp = new Employees__c(Name='Chethan',Employee_ID__c='ZT10275',Business_Unit__c='Quality Assurance',Cost__c='10000');
    List<Employees__c> emps = new List<Employees__c>();
    for(integer i=1;i<=3;i++){
        Employees__c emp = new Employees__c() ;
        emp.Name='Chethann'+i;
        emp.Employee_ID__c='ZT1027'+i;
        emp.Business_Unit__c='Quality Assurance';
        emp.Cost__c=10000;
        emps.add(emp);
    }
        test.starttest();
        insert emps;
        new EmployeeNotworkingForMonthScheduler().execute(null);
        test.stoptest();
    }
    
}