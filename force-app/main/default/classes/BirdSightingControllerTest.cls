@isTest
private class BirdSightingControllerTest {
  @TestSetup
  static void setupData() {
    Bird_Species__c species = new Bird_Species__c(
      Name = 'Northern Cardinal',
      Scientific_Name__c = 'Cardinalis cardinalis',
      Family__c = 'Cardinalidae',
      Conservation_Status__c = 'Least Concern',
      Average_Size_Cm__c = 21
    );
    insert species;

    Birding_Location__c location = new Birding_Location__c(
      Name = 'Willow Creek Marsh',
      Country__c = 'USA',
      Region__c = 'Midwest',
      Habitat_Type__c = 'Wetland'
    );
    insert location;

    insert new Bird_Sighting__c(
      Bird_Species__c = species.Id,
      Birding_Location__c = location.Id,
      Sighting_Date__c = Date.today(),
      Quantity_Observed__c = 3,
      Weather_Conditions__c = 'Sunny',
      Notes__c = 'Seen near the reeds at dawn.'
    );

    // BirdSightingController's SOQL uses WITH SECURITY_ENFORCED, so the running
    // user needs FLS on the fields it selects. New orgs don't grant that
    // automatically, so grant it here via the same permission set real users
    // get, rather than assuming profile-level access.
    PermissionSet birdWatchAdmin = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'Bird_Watch_Admin'
      LIMIT 1
    ];
    insert new PermissionSetAssignment(
      AssigneeId = UserInfo.getUserId(),
      PermissionSetId = birdWatchAdmin.Id
    );
  }

  @isTest
  static void testGetRecentSightingsReturnsRecordsWithRelatedData() {
    List<Bird_Sighting__c> results;
    // System.runAs, even for the same running user, forces Salesforce to
    // recompute field-level security for this transaction so the permission
    // set assigned in setupData() takes effect before the query runs.
    System.runAs(currentTestUser()) {
      Test.startTest();
      results = BirdSightingController.getRecentSightings(10);
      Test.stopTest();
    }

    Assert.areEqual(1, results.size(), 'Expected one sighting to be returned');
    Assert.areEqual('Northern Cardinal', results[0].Bird_Species__r.Name);
    Assert.areEqual('Willow Creek Marsh', results[0].Birding_Location__r.Name);
  }

  @isTest
  static void testGetRecentSightingsDefaultsLimitWhenNullOrInvalid() {
    List<Bird_Sighting__c> resultsNull;
    List<Bird_Sighting__c> resultsNegative;
    System.runAs(currentTestUser()) {
      Test.startTest();
      resultsNull = BirdSightingController.getRecentSightings(null);
      resultsNegative = BirdSightingController.getRecentSightings(-5);
      Test.stopTest();
    }

    Assert.areEqual(
      1,
      resultsNull.size(),
      'Null limit should fall back to the default'
    );
    Assert.areEqual(
      1,
      resultsNegative.size(),
      'Non-positive limit should fall back to the default'
    );
  }

  private static User currentTestUser() {
    return [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
  }
}
