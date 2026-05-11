global class EmployeeNotworkingForMonthScheduler implements Schedulable {
    
    
    global  void execute(SchedulableContext sc)
     {
         
         List<Employees__c> empList = [Select id,Name from Employees__c Where Id NOT IN (Select Employee__c from OpportunityEmployees__c)];         
        
         Employee_Not_Working_For_Month__c emp = new Employee_Not_Working_For_Month__c();
         emp.name =String.valueOf(System.today());
         
         
       
          for(Employees__c empList1: empList)
        {
        
            if(emp.Employees_Names__c == null)
            {
                emp.Employees_Names__c = empList1.name+'\n';
            }
            else
            {emp.Employees_Names__c += empList1.name+'\n';}
            
        }
         
         if(emp != null){insert emp;} 
         
     }
    
    

}