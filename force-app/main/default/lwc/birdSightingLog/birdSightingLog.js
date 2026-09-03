import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getRecentSightings from "@salesforce/apex/BirdSightingController.getRecentSightings";
import BIRD_SIGHTING_OBJECT from "@salesforce/schema/Bird_Sighting__c";

export default class BirdSightingLog extends LightningElement {
  objectApiName = BIRD_SIGHTING_OBJECT;

  showForm = false;
  wiredSightingsResult;
  sightings = [];
  error;

  @wire(getRecentSightings, { maxRecords: 20 })
  wiredSightings(result) {
    this.wiredSightingsResult = result;
    if (result.data) {
      this.sightings = result.data.map((sighting) => ({
        ...sighting,
        speciesName: sighting.Bird_Species__r?.Name,
        scientificName: sighting.Bird_Species__r?.Scientific_Name__c,
        locationName: sighting.Birding_Location__r?.Name,
        locationSummary: [
          sighting.Birding_Location__r?.Region__c,
          sighting.Birding_Location__r?.Country__c
        ]
          .filter(Boolean)
          .join(", ")
      }));
      this.error = undefined;
    } else if (result.error) {
      this.error = result.error;
      this.sightings = [];
    }
  }

  get hasSightings() {
    return this.sightings.length > 0;
  }

  get toggleButtonLabel() {
    return this.showForm ? "Cancel" : "Log a Sighting";
  }

  get toggleButtonVariant() {
    return this.showForm ? "neutral" : "brand";
  }

  handleToggleForm() {
    this.showForm = !this.showForm;
  }

  handleSuccess() {
    this.showForm = false;
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Sighting logged",
        message:
          "Thanks for the report! It now appears in the recent sightings list.",
        variant: "success"
      })
    );
    return refreshApex(this.wiredSightingsResult);
  }

  handleError(event) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Could not log sighting",
        message: event.detail?.detail || "Please check the form and try again.",
        variant: "error"
      })
    );
  }
}
