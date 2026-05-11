@isTest
public class NumberTOWordConvertionTest {
    @isTest
    public static void testNumberTOWordConvertion() {
       
        Decimal testAmount1 = 1234567.89;
        Decimal testAmount2 = 987654321.12;
        Decimal testAmount3 = 0.01;
        NumberTOWordConvertion converter = new NumberTOWordConvertion();
        String result1 = converter.getNumberTOWordConvertion(testAmount1);
        
        String result2 = converter.getNumberTOWordConvertion(testAmount2);
        
        String result3 = converter.getNumberTOWordConvertion(testAmount3);
        
        String resultZero = converter.getNumberTOWordConvertion(0);
        
        
        String resultLarge = converter.getNumberTOWordConvertion(999999999.99);
        
    }
    
    
}