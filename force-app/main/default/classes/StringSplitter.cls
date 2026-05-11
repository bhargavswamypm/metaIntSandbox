public class StringSplitter {

    // Reusable static method that any Apex class can call
    public static List<String> splitStringUtility(String input) {

        List<String> splitValues = new List<String>();
        for (String part : input.split(';')) {
            if (!String.isBlank(part)) {
                splitValues.add(part.trim());
            }
        }
        return splitValues;
    }
}