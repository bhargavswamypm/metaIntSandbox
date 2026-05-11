public with sharing class GoldPriceService {

    public static void fetchAndSaveGoldPrice() {

        // 🔑 Put your real API key here
        String apiKey = '354feb6e3a3bee8103f9ddaaa9259ef4';

        String endpoint = 'https://api.metalpriceapi.com/v1/latest'
                        + '?api_key=' + apiKey
                        + '&base=INR'
                        + '&currencies=XAU';

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');

        HttpResponse res = http.send(req);

        System.debug('STATUS CODE = ' + res.getStatusCode());
        System.debug('RESPONSE BODY = ' + res.getBody());

        if (res.getStatusCode() != 200) {
            System.debug('❌ API Error: ' + res.getBody());
            return;
        }

        // Parse JSON safely
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        if (!result.containsKey('rates')) {
            System.debug('❌ Rates not found in response');
            return;
        }

        Map<String, Object> rates = (Map<String, Object>) result.get('rates');

        if (rates == null || !rates.containsKey('XAU')) {
            System.debug('❌ XAU rate not found in response');
            return;
        }

        // XAU rate = ounces per INR, so invert
        Decimal xauRate = Decimal.valueOf(String.valueOf(rates.get('XAU')));

        if (xauRate == 0) {
            System.debug('❌ Invalid XAU rate');
            return;
        }

        // INR per ounce
        Decimal pricePerOunceINR = 1 / xauRate;

        // Ounce → gram
        Decimal pricePerGram24K = pricePerOunceINR / 31.1035;

        // 22K = 91.6% purity
        Decimal pricePerGram22K = pricePerGram24K * 0.916;

        Date today = Date.today();
        String todayStr = String.valueOf(today);

        List<Gold_Price__c> records = new List<Gold_Price__c>();

        // 24K Record
        records.add(new Gold_Price__c(
            Name = 'Bengaluru 24K - ' + todayStr,
            Date__c = today,
            City__c = 'Bengaluru',
            Carat__c = '24K',
            Price_per_Gram__c = pricePerGram24K.setScale(2),
            CurrencyIsoCode = 'INR',
            Source__c = 'MetalpriceAPI'
        ));

        // 22K Record
        records.add(new Gold_Price__c(
            Name = 'Bengaluru 22K - ' + todayStr,
            Date__c = today,
            City__c = 'Bengaluru',
            Carat__c = '22K',
            Price_per_Gram__c = pricePerGram22K.setScale(2),
            CurrencyIsoCode = 'INR',
            Source__c = 'MetalpriceAPI'
        ));

        insert records;

        System.debug('✅ Gold prices saved successfully with proper name and INR!');
    }
}