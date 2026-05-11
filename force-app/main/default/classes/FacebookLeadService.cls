public class FacebookLeadService {
    
    private static final String FACEBOOK_API_VERSION = 'v23.0';
    private static final String BASE_URL = 'https://graph.facebook.com/' + FACEBOOK_API_VERSION;
    
    /**
     * Get individual lead by ID (for webhook processing)
     */
    public static FacebookLead getLeadById(String leadgenId) {
        try {
            String accessToken = getAccessToken();
            String url = BASE_URL + '/' + leadgenId + '?access_token=' + accessToken;
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod('GET');
            req.setTimeout(60000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                return parseSingleLead(res.getBody());
            } else {
                System.debug('Facebook API Error: ' + res.getStatusCode() + ' - ' + res.getBody());
                return null;
            }
            
        } catch (Exception e) {
            System.debug('Exception in getLeadById: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * Parse single lead response from Facebook
     */
    private static FacebookLead parseSingleLead(String responseBody) {
        try {
            Map<String, Object> leadData = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            FacebookLead lead = new FacebookLead();
            lead.facebookId = (String) leadData.get('id');
            lead.createdTime = (String) leadData.get('created_time');
            
            // Parse field data
            List<Object> fieldData = (List<Object>) leadData.get('field_data');
            lead.fieldData = new Map<String, String>();
            
            if (fieldData != null) {
                for (Object fieldObj : fieldData) {
                    Map<String, Object> field = (Map<String, Object>) fieldObj;
                    String fieldName = (String) field.get('name');
                    List<Object> values = (List<Object>) field.get('values');
                    if (values != null && !values.isEmpty()) {
                        lead.fieldData.put(fieldName, (String) values[0]);
                    }
                }
            }
            
            return lead;
            
        } catch (Exception e) {
            System.debug('Error parsing Facebook lead: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * Get access token from custom settings
     */
    private static String getAccessToken() {
        Facebook_Integration_Settings__c settings = Facebook_Integration_Settings__c.getInstance();
        return settings != null ? settings.Access_Token__c : '';
    }
    
    /**
     * Get app secret from custom settings
     */
    public static String getAppSecret() {
        Facebook_Integration_Settings__c settings = Facebook_Integration_Settings__c.getInstance();
        return settings != null ? settings.App_Secret__c : '';
    }
    
    /**
     * Get webhook verify token from custom settings
     */
    public static String getWebhookVerifyToken() {
        Facebook_Integration_Settings__c settings = Facebook_Integration_Settings__c.getInstance();
        return settings != null ? settings.Webhook_Verify_Token__c : '';
    }
}