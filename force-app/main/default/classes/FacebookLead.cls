public class FacebookLead {
  public String facebookId { get; set; }
  public String createdTime { get; set; }
  public Map<String, String> fieldData { get; set; }
  public FacebookLead() {
    fieldData = new Map<String, String>();
  }
}