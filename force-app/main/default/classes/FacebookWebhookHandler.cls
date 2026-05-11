@RestResource(urlMapping='/facebook/webhook/*')
global class FacebookWebhookHandler {
    
    @HttpGet
    global static void verifyWebhook() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            String mode = req.params.get('hub.mode');
            String token = req.params.get('hub.verify_token');
            String challenge = req.params.get('hub.challenge');
            
            String verifyToken = FacebookLeadService.getWebhookVerifyToken();
            
            System.debug('Webhook verification - Mode: ' + mode);
            
            if (mode == 'subscribe' && token == verifyToken) {
                System.debug('Webhook verified successfully');
                res.responseBody = Blob.valueOf(challenge);
                res.statusCode = 200;
            } else {
                System.debug('Webhook verification failed');
                res.statusCode = 403;
            }
        } catch (Exception e) {
            System.debug('Webhook verification error: ' + e.getMessage());
            res.statusCode = 500;
        }
    }
    
    @HttpPost
    global static void handleWebhook() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            String body = req.requestBody.toString();
            System.debug('Facebook webhook received: ' + body);
            
            // Verify the request signature (recommended for security)
            String signature = req.headers.get('X-Hub-Signature-256');
            if (!verifySignature(body, signature)) {
                System.debug('Invalid webhook signature');
                res.statusCode = 401;
                return;
            }
            
            // Parse webhook payload
            Map<String, Object> webhookData = (Map<String, Object>) JSON.deserializeUntyped(body);
            
            if (webhookData.containsKey('entry')) {
                List<Object> entries = (List<Object>) webhookData.get('entry');
                processWebhookEntries(entries);
            }
            
            // Always return 200 to Facebook
            res.statusCode = 200;
            
        } catch (Exception e) {
            System.debug('Webhook processing error: ' + e.getMessage());
            res.statusCode = 200; // Return 200 to avoid Facebook retries
        }
    }
    
    /**
     * Process webhook entries for leadgen events
     */
    private static void processWebhookEntries(List<Object> entries) {
        List<String> leadgenIds = new List<String>();
        
        for (Object entryObj : entries) {
            Map<String, Object> entry = (Map<String, Object>) entryObj;
            
            if (entry.containsKey('changes')) {
                List<Object> changes = (List<Object>) entry.get('changes');
                
                for (Object changeObj : changes) {
                    Map<String, Object> change = (Map<String, Object>) changeObj;
                    
                    // Only process leadgen events
                    if ('leadgen'.equals(change.get('field'))) {
                        Map<String, Object> value = (Map<String, Object>) change.get('value');
                        String leadgenId = (String) value.get('leadgen_id');
                        
                        if (String.isNotBlank(leadgenId)) {
                            leadgenIds.add(leadgenId);
                        }
                    }
                }
            }
        }
        
        // Process leads asynchronously
        if (!leadgenIds.isEmpty()) {
            processLeadsAsync(leadgenIds);
        }
    }
    
    /**
     * Process leads asynchronously to avoid timeout
     */
    @future(callout=true)
    private static void processLeadsAsync(List<String> leadgenIds) {
        for (String leadgenId : leadgenIds) {
            try {
                FacebookLead fbLead = FacebookLeadService.getLeadById(leadgenId);
                if (fbLead != null) {
                    FacebookLeadConverter.processLead(fbLead);
                }
            } catch (Exception e) {
                System.debug('Error processing lead ' + leadgenId + ': ' + e.getMessage());
            }
        }
    }
    
    /**
     * Verify webhook signature from Facebook
     */
    private static Boolean verifySignature(String payload, String signature) {
        if (String.isBlank(signature) || !signature.startsWith('sha256=')) {
            return false;
        }
        
        try {
            String expectedSignature = 'sha256=' + 
                EncodingUtil.convertToHex(
                    Crypto.generateMac('HmacSHA256', 
                        Blob.valueOf(payload), 
                        Blob.valueOf(FacebookLeadService.getAppSecret())
                    )
                );
            
            return signature.equals(expectedSignature);
        } catch (Exception e) {
            System.debug('Signature verification error: ' + e.getMessage());
            return false;
        }
    }
}