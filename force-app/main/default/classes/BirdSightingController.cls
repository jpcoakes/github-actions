public with sharing class BirdSightingController {
  private static final Integer DEFAULT_LIMIT = 20;

  @AuraEnabled(cacheable=true)
  public static List<Bird_Sighting__c> getRecentSightings(Integer maxRecords) {
    Integer recordLimit = (maxRecords == null ||
      maxRecords <= 0)
      ? DEFAULT_LIMIT
      : maxRecords;

    return [
      SELECT
        Id,
        Name,
        Sighting_Date__c,
        Quantity_Observed__c,
        Weather_Conditions__c,
        Verified__c,
        Notes__c,
        Bird_Species__r.Name,
        Bird_Species__r.Scientific_Name__c,
        Birding_Location__r.Name,
        Birding_Location__r.Region__c,
        Birding_Location__r.Country__c
      FROM Bird_Sighting__c
      WITH SECURITY_ENFORCED
      ORDER BY Sighting_Date__c DESC, CreatedDate DESC
      LIMIT :recordLimit
    ];
  }
}
