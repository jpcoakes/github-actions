import { createElement } from "lwc";
import { registerApexTestWireAdapter } from "@salesforce/sfdx-lwc-jest";
import BirdSightingLog from "c/birdSightingLog";
import getRecentSightings from "@salesforce/apex/BirdSightingController.getRecentSightings";
import mockSightings from "./data/getRecentSightings.json";

const getRecentSightingsAdapter =
  registerApexTestWireAdapter(getRecentSightings);

describe("c-bird-sighting-log", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders a row for each returned sighting", async () => {
    const element = createElement("c-bird-sighting-log", {
      is: BirdSightingLog
    });
    document.body.appendChild(element);

    getRecentSightingsAdapter.emit(mockSightings);
    await Promise.resolve();

    const rows = element.shadowRoot.querySelectorAll("li.slds-item");
    expect(rows.length).toBe(mockSightings.length);
  });

  it("shows an empty state message when there are no sightings", async () => {
    const element = createElement("c-bird-sighting-log", {
      is: BirdSightingLog
    });
    document.body.appendChild(element);

    getRecentSightingsAdapter.emit([]);
    await Promise.resolve();

    const emptyMessage = element.shadowRoot.querySelector("p.empty-state");
    expect(emptyMessage).not.toBeNull();
    expect(emptyMessage.textContent).toContain("No sightings logged yet");
  });

  it("toggles the log-a-sighting form when the action button is clicked", async () => {
    const element = createElement("c-bird-sighting-log", {
      is: BirdSightingLog
    });
    document.body.appendChild(element);

    getRecentSightingsAdapter.emit([]);
    await Promise.resolve();

    expect(
      element.shadowRoot.querySelector("lightning-record-edit-form")
    ).toBeNull();

    const button = element.shadowRoot.querySelector("lightning-button");
    button.click();
    await Promise.resolve();

    expect(
      element.shadowRoot.querySelector("lightning-record-edit-form")
    ).not.toBeNull();
  });
});
