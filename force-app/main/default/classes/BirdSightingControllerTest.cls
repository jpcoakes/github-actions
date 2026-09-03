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
  }

  @isTest
  static void testGetRecentSightingsReturnsRecordsWithRelatedData() {
    Test.startTest();
    List<Bird_Sighting__c> results = BirdSightingController.getRecentSightings(
      10
    );
    Test.stopTest();

    Assert.areEqual(1, results.size(), 'Expected one sighting to be returned');
    Assert.areEqual('Northern Cardinal', results[0].Bird_Species__r.Name);
    Assert.areEqual('Willow Creek Marsh', results[0].Birding_Location__r.Name);
  }

  @isTest
  static void testGetRecentSightingsDefaultsLimitWhenNullOrInvalid() {
    Test.startTest();
    List<Bird_Sighting__c> resultsNull = BirdSightingController.getRecentSightings(
      null
    );
    List<Bird_Sighting__c> resultsNegative = BirdSightingController.getRecentSightings(
      -5
    );
    Test.stopTest();

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
}
