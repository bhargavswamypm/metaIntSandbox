@isTest
public class StringSplitterTest {

        
    @isTest
    static void testSplitStringUtility_BasicSplit() {
        String input = 'value1;value2;value3';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(3, result.size(), 'Should return 3 values');
        System.assertEquals('value1', result[0], 'First value should match');
        System.assertEquals('value2', result[1], 'Second value should match');
        System.assertEquals('value3', result[2], 'Third value should match');
    }
    
    @isTest
    static void testSplitStringUtility_SingleValue() {
        String input = 'singleValue';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Should return 1 value');
        System.assertEquals('singleValue', result[0], 'Value should match');
    }
    
    @isTest
    static void testSplitStringUtility_WithSpaces() {
        String input = 'value1 ; value2 ; value3';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(3, result.size(), 'Should return 3 values');
        System.assertEquals('value1', result[0], 'First value should be trimmed');
        System.assertEquals('value2', result[1], 'Second value should be trimmed');
        System.assertEquals('value3', result[2], 'Third value should be trimmed');
    }
    
    @isTest
    static void testSplitStringUtility_WithLeadingTrailingSpaces() {
        String input = '  value1  ;  value2  ;  value3  ';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(3, result.size(), 'Should return 3 values');
        System.assertEquals('value1', result[0], 'Leading/trailing spaces should be trimmed');
        System.assertEquals('value2', result[1], 'Leading/trailing spaces should be trimmed');
        System.assertEquals('value3', result[2], 'Leading/trailing spaces should be trimmed');
    }
    
    @isTest
    static void testSplitStringUtility_EmptyString() {
        String input = '';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty list for empty string');
    }
    
    @isTest
    static void testSplitStringUtility_OnlySemicolons() {
        String input = ';;;';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty list when only semicolons');
    }
    
    @isTest
    static void testSplitStringUtility_OnlySpaces() {
        String input = '   ';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty list for only spaces');
    }
    
    @isTest
    static void testSplitStringUtility_MixedEmptyValues() {
        String input = 'value1;;value2;;;value3';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(3, result.size(), 'Should skip empty values between semicolons');
        System.assertEquals('value1', result[0], 'First value should match');
        System.assertEquals('value2', result[1], 'Second value should match');
        System.assertEquals('value3', result[2], 'Third value should match');
    }
    
    @isTest
    static void testSplitStringUtility_WithSpecialCharacters() {
        String input = 'value@1;value#2;value$3';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(3, result.size(), 'Should handle special characters');
        System.assertEquals('value@1', result[0], 'Special characters should be preserved');
        System.assertEquals('value#2', result[1], 'Special characters should be preserved');
        System.assertEquals('value$3', result[2], 'Special characters should be preserved');
    }
    
    @isTest
    static void testSplitStringUtility_WithNumbers() {
        String input = '100;200;300;400';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(4, result.size(), 'Should handle numeric strings');
        System.assertEquals('100', result[0], 'Numeric value should match');
        System.assertEquals('200', result[1], 'Numeric value should match');
        System.assertEquals('300', result[2], 'Numeric value should match');
        System.assertEquals('400', result[3], 'Numeric value should match');
    }
    
    @isTest
    static void testSplitStringUtility_LongString() {
        String input = 'value1;value2;value3;value4;value5;value6;value7;value8;value9;value10';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(10, result.size(), 'Should handle long strings with many values');
        System.assertEquals('value1', result[0], 'First value should match');
        System.assertEquals('value10', result[9], 'Last value should match');
    }
    
    @isTest
    static void testSplitStringUtility_WithNewlines() {
        String input = 'value1;\nvalue2;\nvalue3';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(3, result.size(), 'Should handle newlines');
        System.assertEquals('value1', result[0], 'First value should match');
        // Note: trim() removes newlines, so value2 and value3 will be clean
    }
    
    @isTest
    static void testSplitStringUtility_WithTabs() {
        String input = 'value1;\tvalue2;\tvalue3';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(3, result.size(), 'Should handle tabs');
        System.assertEquals('value1', result[0], 'First value should match');
        // trim() removes tabs as well
    }
    
    @isTest
    static void testSplitStringUtility_CaseSensitive() {
        String input = 'Value1;VALUE2;value3';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(3, result.size(), 'Should preserve case');
        System.assertEquals('Value1', result[0], 'Case should be preserved');
        System.assertEquals('VALUE2', result[1], 'Case should be preserved');
        System.assertEquals('value3', result[2], 'Case should be preserved');
    }
    
    @isTest
    static void testSplitStringUtility_TrailingSemicolon() {
        String input = 'value1;value2;value3;';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(3, result.size(), 'Should ignore trailing semicolon');
        System.assertEquals('value1', result[0], 'First value should match');
        System.assertEquals('value2', result[1], 'Second value should match');
        System.assertEquals('value3', result[2], 'Third value should match');
    }
    
    @isTest
    static void testSplitStringUtility_LeadingSemicolon() {
        String input = ';value1;value2;value3';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(3, result.size(), 'Should ignore leading semicolon');
        System.assertEquals('value1', result[0], 'First value should match');
        System.assertEquals('value2', result[1], 'Second value should match');
        System.assertEquals('value3', result[2], 'Third value should match');
    }
    
    @isTest
    static void testSplitStringUtility_UnicodeCharacters() {
        String input = 'café;naïve;résumé';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(3, result.size(), 'Should handle unicode characters');
        System.assertEquals('café', result[0], 'Unicode characters should be preserved');
        System.assertEquals('naïve', result[1], 'Unicode characters should be preserved');
        System.assertEquals('résumé', result[2], 'Unicode characters should be preserved');
    }
    
    @isTest
    static void testSplitStringUtility_RealWorldExample() {
        // Simulating a picklist multi-select field values
        String input = 'Apples;Oranges;Bananas;Grapes';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        System.assertEquals(4, result.size(), 'Should handle real-world multi-select values');
        System.assert(result.contains('Apples'), 'Should contain Apples');
        System.assert(result.contains('Oranges'), 'Should contain Oranges');
        System.assert(result.contains('Bananas'), 'Should contain Bananas');
        System.assert(result.contains('Grapes'), 'Should contain Grapes');
    }
    
    @isTest
    static void testSplitStringUtility_EmptyValuesInMiddle() {
        String input = 'value1; ;value3';
        
        Test.startTest();
        List<String> result = StringSplitter.splitStringUtility(input);
        Test.stopTest();
        
        // Space-only values should be filtered out by isBlank check
        System.assertEquals(2, result.size(), 'Should skip blank values');
        System.assertEquals('value1', result[0], 'First value should match');
        System.assertEquals('value3', result[1], 'Second value should match');
    }
    
}