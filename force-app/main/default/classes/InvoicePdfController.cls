public class InvoicePdfController {
    
    Public Id id = ApexPages.currentPage().getParameters().get('Id');
    public String Idholder;
    public Invoice__c invoice {get; set;}
    public Opportunity opportunity {get; set;}
    public Account account {get; set;}
    public Contact contact {get;set;}
    public Decimal lineItemTotal{get;set;}
    public Decimal totalDue{get;set;}
    public List<InvoiceLineItems__c> invoiceLineItem {get; set;}
    public Map<String, Decimal> lineItemDetails {get; set;}
    public String  clientname{get; set;}
    DateTime myDateTime;
    public String invoicedate{get;set;}
    public Decimal TotalAmount {get;set;}
    public Decimal TotalAmountAfterTax {get;set;}
    public String numInWords {get;set;}
    public String numInWordsUsd {get;set;}
    public Decimal UsCall {get;set;}
    public Decimal NightShift {get;set;}
    public Decimal PstShift {get;set;}
    public String HSNSAC {get;set;}
    public String AccHolName {get;set;}
    public String AccNum {get;set;}
    public String BankName {get;set;}
    public String BankAdd {get;set;}
    public String SwiftC {get;set;}
    public String Gstlut {get;set;}
    public String CInvoiceId {get;set;}
    public String PONumber {get;set;}
    public String CompName {get;set;}
    public String OAdd1 {get;set;}
    public String OAdd2 {get;set;}
    public String Gst {get;set;}
    public String pan {get;set;}
    public String phone {get;set;}
    public String email {get;set;}
    public Integer col {get;set;} 
    
        public class GroupedLineItem {
        public String designation { get; set; }
        public Decimal cost { get; set; }
        public Integer quantity { get; set; }
        public Decimal us { get; set; }        
        public Decimal night { get; set; }        
        public Decimal weekend { get; set; }
        public Decimal pst { get; set; }          
        public Decimal totalCost { get; set; }
        public Decimal usAl { get; set; }        
        public Decimal nightAl { get; set; }        
        public Decimal weekendAl { get; set; }
        public Decimal pstAl { get; set; }          
        public Decimal totalCostAl { get; set; }
    	public Boolean lessWorkingDays { get; set; } // New field 
        public Decimal workingDays { get; set; }
    }

    public List<GroupedLineItem> groupedLineItems { get; set; }


    
    public InvoicePdfController(ApexPages.StandardController standardPageController) {
        col = 3;
        Idholder=ApexPages.CurrentPage().getparameters().get('id');
        
        this.invoice = [Select Id,Name,Invoice_Date__c,Opportunity__c,	Total_amount__c,Business_Location__c,Concatenate_with_id__c,Night_Shift_Overall_Count__c,
                        Days_in_the_month__c,End_Date__c,Name__c,Selected_Days__c,	Start_Date__c,Regenerate_PDF__c,PO_Number__c,PST_Shift_Overall_Count__c,
                        Night_Shift_Expense__c,PST_Shift_Expense__c,US_Call_Expense__c,HSN_SAC1__c,Total_Amount_After_Tax__c,Invoice_Type__c,Invoice_Month_No__c,Invoice_Id_For_VF__c,
                        Account_Holder_Name__c,Account_Number__c,Bank_Name__c,	Bank_Address__c,Swift_Code__c,GST_LUT_ARN__c,US_Call_Overall_Count__c,Weekend_Overall_Count__c,
                        Company_Name__c,Address_Line_1__c,Address_Line_2__c,GST_Number__c,Pan_No__c,Phone__c,Email__c,Club_All_Individual_Allowances__c,Total_US_Cost__c,Total_PST_Cost__c,Total_Night_Cost__c,Total_Weekend_Cost__c,
                        (SELECT Id,Name,Employee__c,Cost__c,Total_Cost__c,InvoiceId__c,Designation__c,Employee_ID__c,
                         Night_Shift__c,Night_Shift_Allowances__c,PST_Shift__c,PST_Shift_Allowances__c,Selected_Days__c,
                         Shift_Allowances__c,US_Call__c,US_Call_Allowances__c,Weekend__c,Weekend_Allowances__c,Weekend_Expense__c
                         FROM Invoicelineitems__r ORDER BY Employee_ID__c ASC) From Invoice__c where id=: Idholder ];
        system.debug('invoive'+this.invoice);
        this.TotalAmount = this.invoice.Total_amount__c;

        this.UsCall = this.invoice.US_Call_Expense__c;
        this.PstShift = this.invoice.PST_Shift_Expense__c;
        this.NightShift = this.invoice.Night_Shift_Expense__c;
        this.HSNSAC = this.invoice.HSN_SAC1__c;
        this.PONumber = this.invoice.PO_Number__c;
        
        this.CompName = this.invoice.Company_Name__c ;
        this.OAdd1 = this.invoice.Address_Line_1__c;
        this.OAdd2 = this.invoice.Address_Line_2__c;
        this.gst = this.invoice.GST_Number__c;
        this.pan = this.invoice.Pan_No__c;
        this.phone = this.invoice.Phone__c;
        this.email = this.invoice.Email__c;
        
        
        if(this.invoice.Regenerate_PDF__c == true){

			   this.CInvoiceId = this.invoice.Invoice_Id_For_VF__c+this.invoice.Concatenate_with_id__c ;
            
        }
        
        if(this.invoice.Total_Amount_After_Tax__c != null && (this.invoice.Business_Location__c == 'State' || this.invoice.Business_Location__c == 'Domestic') ){
            NumberTOWordConvertion nwcObj = new NumberTOWordConvertion();
            this.numInWords = nwcObj.getNumberTOWordConvertion(this.invoice.Total_Amount_After_Tax__c);
        }
        
        if(this.invoice.Total_amount__c != null && this.invoice.Business_Location__c == 'International'){
            NumberTOWordConvertionUSD nwcObj = new NumberTOWordConvertionUSD();
            this.numInWordsUsd = nwcObj.getNumberTOWordConvertion(this.invoice.Total_amount__c);
        }
        
        
        if (invoice != null) {
            System.debug('in line 24');
            opportunity = [SELECT Id, Name,Account.Name,Account.Phone,Account.BillingStreet,Account.BillingCity,
                           Account.BillingState,Account.BillingPostalCode,Account.BillingCountry,Account.email__c
                           FROM Opportunity WHERE Id = :invoice.Opportunity__c];
            System.debug('opportunity'+opportunity);
            //account = [SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry FROM Account WHERE Id = :invoice.Account__c];
            //contact = [SELECT Id, Name, Title FROM Contact WHERE Id = :opportunity.Contact__c];

            invoiceLineItem = [SELECT Id,Name,Employee__c,Employee__r.name,Employee__r.Designation__c,Cost__c,Total_Cost__c,InvoiceId__c,Designation__c,Employee_ID__c,
                               Night_Shift__c,Night_Shift_Allowances__c,PST_Shift__c,PST_Shift_Allowances__c,Selected_Days__c,
                               Shift_Allowances__c,US_Call__c,US_Call_Allowances__c,Weekend__c,Weekend_Allowances__c,Weekend_Expense__c,
                               Comment__c,Salary_for_Working_Days__c,No_Working_Days__c,Less_Working_Days__c,
                               US_Call_Allowances_display__c,Weekend_Allowances_display__c,Night_Shift_Allowances_display__c,PST_Shift_Allowances_display__c,InvoiceId__r.Club_All_Individual_Allowances__c
                               FROM InvoiceLineItems__c WHERE InvoiceId__c = :invoice.Id];
            System.debug('invoiceline 28'+invoice.Id);
            System.debug('invoiceLineItem is'+invoiceLineItem);
            lineItemDetails = new Map<string, Decimal>();
            if (invoiceLineItem != null && !invoiceLineItem.isEmpty()) {
                for (InvoiceLineItems__c lineItem : invoiceLineItem) {
                    lineItemDetails.put(lineItem.id, lineItem.Total_Cost__c);
                }
            }
            
            if (invoice.Total_amount__c == null) {
                lineItemTotal = 0;
            } else {
                lineItemTotal = invoice.Total_amount__c;
            }
            
            totalDue = lineItemTotal;
            
            // Converting and generating Invoice Date
            if (invoice.Invoice_Date__c != null) {
                myDateTime = (DateTime) invoice.Invoice_Date__c.addDays(1);
                invoicedate = myDateTime.format('MM/dd/yyyy');
            }
            
            if (invoice.Invoice_Type__c == 'Designation based') {
            	groupLineItemsByDesignation();
              	invoiceLineItem.clear();
                col = 2;
        	}            

        } 

    }

private void groupLineItemsByDesignation() {
    Map<String, GroupedLineItem> regularMap = new Map<String, GroupedLineItem>();
    Map<String, GroupedLineItem> lessWorkingDaysMap = new Map<String, GroupedLineItem>();
    Map<String, GroupedLineItem> groupedMap = new Map<String, GroupedLineItem>();
    
    for (InvoiceLineItems__c lineItem : invoiceLineItem) {
        String designation = lineItem.Employee__r.Designation__c;
        Boolean lessWorkingDays = lineItem.Less_Working_Days__c;
        Decimal workingDays = lineItem.No_Working_Days__c;
        Decimal cost = lineItem.Cost__c != null ? lineItem.Cost__c : 0;
        Decimal usCall = lineItem.US_Call__c != null ? lineItem.US_Call__c : 0;
        Decimal pstShift = lineItem.PST_Shift__c != null ? lineItem.PST_Shift__c : 0;
        Decimal nightShift = lineItem.Night_Shift__c != null ? lineItem.Night_Shift__c : 0;
        Decimal weekendShift = lineItem.Weekend__c != null ? lineItem.Weekend__c : 0;            
        Decimal usCallAllowance = lineItem.US_Call_Allowances__c != null ? lineItem.US_Call_Allowances__c : 0;
        Decimal pstShiftAllowance = lineItem.PST_Shift_Allowances__c != null ? lineItem.PST_Shift_Allowances__c : 0;
        Decimal nightShiftAllowance = lineItem.Night_Shift_Allowances__c != null ? lineItem.Night_Shift_Allowances__c : 0;
        Decimal weekendShiftAllowance = lineItem.Weekend_Allowances__c != null ? lineItem.Weekend_Allowances__c : 0; 
        String key = designation + workingDays;
        Map<String, GroupedLineItem> targetMap = lessWorkingDays ? lessWorkingDaysMap : regularMap;
        
            if (groupedMap.containsKey(key)) {
                GroupedLineItem groupnew = groupedMap.get(key);
                
                groupnew.quantity++;
                groupnew.totalCost += cost;
        } else {
            GroupedLineItem groupnew = createNewGroupedLineItem(designation, cost, usCall, pstShift, nightShift, weekendShift, 
                                                                usCallAllowance, pstShiftAllowance, nightShiftAllowance, weekendShiftAllowance);
                groupnew.designation = designation;
                groupnew.lessWorkingDays = lessWorkingDays;
                groupnew.workingDays = workingDays;
                groupnew.quantity = 1;
                groupnew.totalCost = cost;
                groupedMap.put(key, groupnew);
        }
    }
    
    groupedLineItems = new List<GroupedLineItem>(groupedMap.values());
    groupedLineItems.addAll(regularMap.values());
    groupedLineItems.addAll(lessWorkingDaysMap.values());
}

private void updateGroupedLineItem(GroupedLineItem groupnew, Decimal cost, Decimal usCall, Decimal pstShift, Decimal nightShift, Decimal weekendShift, 
                                   Decimal usCallAllowance, Decimal pstShiftAllowance, Decimal nightShiftAllowance, Decimal weekendShiftAllowance) {
    groupnew.totalCost += cost;
    if(cost > 0) {
        groupnew.quantity++;
    }
    groupnew.usAl += usCallAllowance;
    groupnew.us += usCall;
    groupnew.pstAl += pstShiftAllowance;
    groupnew.pst += pstShift;
    groupnew.nightAl += nightShiftAllowance;
    groupnew.night += nightShift;
    groupnew.weekendAl += weekendShiftAllowance;
    groupnew.weekend += weekendShift;
}

private GroupedLineItem createNewGroupedLineItem(String designation, Decimal cost, Decimal usCall, Decimal pstShift, Decimal nightShift, Decimal weekendShift, 
                                                 Decimal usCallAllowance, Decimal pstShiftAllowance, Decimal nightShiftAllowance, Decimal weekendShiftAllowance) {
    GroupedLineItem groupnew = new GroupedLineItem();
    groupnew.designation = designation;
    groupnew.cost = cost;
    groupnew.quantity = (cost > 0) ? 1 : 0;
    groupnew.totalCost = cost;
    groupnew.us = usCall;
    groupnew.usAl = usCallAllowance;
    groupnew.night = nightShift;
    groupnew.nightAl = nightShiftAllowance;
    groupnew.pst = pstShift;
    groupnew.pstAl = pstShiftAllowance;
    groupnew.weekend = weekendShift;
    groupnew.weekendAl = weekendShiftAllowance;
    return groupnew;
}
    
    public void generatePDF() {
        
        if(ApexPages.currentPage().getParameters().containsKey('generatepdf')) {
            return;
        }
        
        List<Attachment> attachListToDel = [SELECT Id,ParentId FROM Attachment WHERE ParentId =: id];
        delete attachListToDel;
        
        PageReference pdfPage = ApexPages.currentPage();
        pdfPage.getParameters().put('generatepdf','true');
        
        Attachment attach = new Attachment();
        Blob pdfBlob;
        try {
            pdfBlob = pdfPage.getContent();
        }catch (VisualforceException e) {
            pdfBlob = Blob.valueOf('Error Uploading' + e.getMessage());
        }
        
        attach.parentId = id;
        attach.Name = invoice.Name  + '.pdf';
        attach.body = pdfBlob;
        insert attach;
        
    }

    }