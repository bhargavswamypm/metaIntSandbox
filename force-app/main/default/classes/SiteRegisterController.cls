/**
 * Apex controller to register Experience Cloud users
 */
public class SiteRegisterController {
    
    // ===== Form Fields =====
    public String name { get; set; }
    public String email { get; set; }
    public String phone { get; set; }
    public String userType { get; set; }
    public String subUserType { get; set; }
    public String profileId { get; set;}
    public String password { 
        get; 
        set { password = value == null ? value : value.trim(); } 
    }
    public String confirmPassword { 
        get; 
        set { confirmPassword = value == null ? value : value.trim(); } 
    }
    
    public SiteRegisterController() {}
    
    // ===== Picklist Options =====
    public List<SelectOption> getUserTypeOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '-- Select User Type --'));
        for (Schema.PicklistEntry pe : User.UserType__c.getDescribe().getPicklistValues()) {
            if (pe.isActive()) {
                options.add(new SelectOption(pe.getValue(), pe.getLabel()));
            }
        }
        return options;
    }
    
    // ===== Remote Action for Dependent Picklist =====
    @RemoteAction
    public static List<Map<String, String>> getSubUserTypeOptions(String controllingValue) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        
        if (String.isBlank(controllingValue)) {
            return options;
        }
        
        try {
            // Get field describes
            Schema.DescribeFieldResult controllingFieldDescribe = User.UserType__c.getDescribe();
            Schema.DescribeFieldResult dependentFieldDescribe = User.User_SubTyp__c.getDescribe();
            
            // Get all picklist entries
            List<Schema.PicklistEntry> controllingValues = controllingFieldDescribe.getPicklistValues();
            List<Schema.PicklistEntry> dependentValues = dependentFieldDescribe.getPicklistValues();
            
            // Find the index of the selected controlling value
            Integer controllingIndex = -1;
            for (Integer i = 0; i < controllingValues.size(); i++) {
                if (controllingValues[i].getValue() == controllingValue) {
                    controllingIndex = i;
                    break;
                }
            }
            
            if (controllingIndex == -1) {
                System.debug('Controlling value not found: ' + controllingValue);
                return options;
            }
            
            System.debug('Controlling Index: ' + controllingIndex);
            System.debug('Total Dependent Values: ' + dependentValues.size());
            
            // Get dependent values for the controlling value
            for (Schema.PicklistEntry dependentValue : dependentValues) {
                if (!dependentValue.isActive()) {
                    continue;
                }
                
                // Check if this dependent value is valid for the controlling value
                if (isValidForControlling(dependentValue, controllingIndex)) {
                    Map<String, String> option = new Map<String, String>();
                    option.put('value', dependentValue.getValue());
                    option.put('label', dependentValue.getLabel());
                    options.add(option);
                    System.debug('Added option: ' + dependentValue.getLabel());
                }
            }
            
            System.debug('Total options returned: ' + options.size());
        } catch (Exception e) {
            System.debug('Error getting sub user type options: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
        
        return options;
    }
    
    private static Boolean isValidForControlling(
        Schema.PicklistEntry dependentValue,
        Integer controllingIndex
    ) {
        try {
            // Extract validFor string
            String jsonString = JSON.serialize(dependentValue);
            Map<String, Object> fieldMap =
                (Map<String, Object>) JSON.deserializeUntyped(jsonString);
            String validFor = (String) fieldMap.get('validFor');

            // No validFor = not mapped to anything
            if (String.isBlank(validFor)) {
                return false;
            }

            // Salesforce uses 6-bit Base64 chunks
            Integer byteIndex = controllingIndex / 6;

            // 🔥 IMPORTANT: reverse bit order
            Integer bitIndex = 5 - Math.mod(controllingIndex, 6);

            if (byteIndex >= validFor.length()) {
                return false;
            }

            Integer byteValue = base64ToByte(
                validFor.substring(byteIndex, byteIndex + 1)
            );

            return (byteValue & (1 << bitIndex)) != 0;
        } catch (Exception e) {
            System.debug('Dependent picklist decode error: ' + e.getMessage());
            return false;
        }
    }
    
    // Convert Base64 character to byte value
    private static Integer base64ToByte(String c) {
        if (c >= 'A' && c <= 'Z') {
            return c.charAt(0) - 65;
        } else if (c >= 'a' && c <= 'z') {
            return c.charAt(0) - 97 + 26;
        } else if (c >= '0' && c <= '9') {
            return c.charAt(0) - 48 + 52;
        } else if (c == '+') {
            return 62;
        } else if (c == '/') {
            return 63;
        }
        return 0;
    }
    
    // ===== Create Person Account =====
    private Id createPersonAccount() {
        try {
            // Get Person Account Record Type
            Id personRecordTypeId = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'Account' 
                AND IsPersonType = true 
                LIMIT 1
            ].Id;
            
            Account personAcct = new Account(
                FirstName = '',
                LastName = name,
                PersonEmail = email,
                Phone = phone,
                RecordTypeId = personRecordTypeId
            );
            insert personAcct;
            return personAcct.Id;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Failed to create Person Account: ' + e.getMessage()
            ));
            System.debug('Person Account Creation Error: ' + e.getMessage());
            return null;
        }
    }
    
    // ===== Registration Logic =====
    public PageReference registerUser() {
        // Collect errors
        List<String> errors = new List<String>();

        if (String.isBlank(name)) errors.add('Name is required');
        if (String.isBlank(email)) errors.add('Email is required');
        if (String.isBlank(phone)) errors.add('Phone number is required');
        if (String.isBlank(password)) errors.add('Password is required');
        if (String.isBlank(confirmPassword)) errors.add('Confirm Password is required');
        if (!String.isBlank(password) && !String.isBlank(confirmPassword)
            && password != confirmPassword) {
            errors.add('Passwords do not match');
        }
        if (String.isBlank(userType)) errors.add('Please select a User Type');
        
        // Only validate subUserType if it's required (i.e., if there are sub-types for the selected user type)
        List<Map<String, String>> subTypeOptions = getSubUserTypeOptions(userType);
        if (!subTypeOptions.isEmpty() && String.isBlank(subUserType)) {
            errors.add('Please select a Sub User Type');
        }

        // Show all errors together
        if (!errors.isEmpty()) {
            String message = 'Please fix the following:\n• ' + String.join(errors, '\n• ');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
            return null;
        }
        
        // Create Person Account
        Id accountId = createPersonAccount();
        if (accountId == null) {
            return null;
        }
        
        // Create User
        User u = new User();
        u.Username = email;
        u.Email = email;
        u.FirstName = '';
        u.LastName = name;
        u.CommunityNickname = email.substringBefore('@') + String.valueOf(System.now().getTime()).right(4);
        u.Phone = phone;
        u.UserType__c = userType;
        
        // Only set subUserType if it has a value
        if (String.isNotBlank(subUserType)) {
            u.User_SubTyp__c = subUserType;
        }
        
        // REQUIRED FIELDS
        u.Alias = name.length() > 8 ? name.substring(0, 8) : name;
        u.TimeZoneSidKey = 'Asia/Kolkata';
        u.LocaleSidKey = 'en_IN';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community User' LIMIT 1].Id;
        
        // Create Experience Cloud user
        String userId;
        try {
            userId = Site.createPortalUser(u, accountId, password);
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Registration failed: ' + e.getMessage()
            ));
            System.debug('Registration Error: ' + e.getMessage());
            return null;
        }
        
        // Login or confirmation
        if (userId != null) {
            if (String.isNotBlank(password)) {
                PageReference loginPage = Site.login(email, password, null);
                if (loginPage != null) {
                    return loginPage;
                } else {
                    ApexPages.addMessage(new ApexPages.Message(
                        ApexPages.Severity.ERROR,
                        'User created but auto-login failed. Please try logging in manually.'
                    ));
                }
            } else {
                PageReference confirmPage = System.Page.SiteRegisterConfirm;
                confirmPage.setRedirect(true);
                return confirmPage;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'User creation failed. Please try again or contact support.'
            ));
        }
        
        return null;
    }
}