@isTest
public class FacebookWebhookTest {
    
    @TestSetup
    static void setup() {
        // Create test custom setting
        Facebook_Integration_Settings__c settings = new Facebook_Integration_Settings__c();
        settings.App_Secret__c = 'test_secret';
        settings.Access_Token__c = 'test_token';
        settings.Webhook_Verify_Token__c = 'test_verify_token';
        insert settings;
    }
    
    @isTest
    static void testWebhookVerification() {
        Test.startTest();
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/facebook/webhook/';
        req.httpMethod = 'GET';
        req.addParameter('hub.mode', 'subscribe');
        req.addParameter('hub.verify_token', 'test_verify_token');
        req.addParameter('hub.challenge', 'test_challenge');
        
        RestContext.request = req;
        RestContext.response = res;
        
        FacebookWebhookHandler.verifyWebhook();
        
        Test.stopTest();
        
        System.assertEquals(200, res.statusCode);
        System.assertEquals('test_challenge', res.responseBody.toString());
    }
    
    @isTest
    static void testLeadConversion() {
        FacebookLead fbLead = new FacebookLead();
        fbLead.facebookId = 'test123';
        fbLead.fieldData.put('first_name', 'John');
        fbLead.fieldData.put('last_name', 'Doe');
        fbLead.fieldData.put('email', 'john@example.com');
        
        Test.startTest();
        FacebookLeadConverter.processLead(fbLead);
        Test.stopTest();
        
        List<Lead> leads = [SELECT FirstName, LastName, Email FROM Lead];
        System.assertEquals(1, leads.size());
        System.assertEquals('John', leads[0].FirstName);
        System.assertEquals('john@example.com', leads[0].Email);
    }
}