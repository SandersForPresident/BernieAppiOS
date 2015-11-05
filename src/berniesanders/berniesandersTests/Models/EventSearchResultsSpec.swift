import Quick
import Nimble
import CoreLocation

@testable import berniesanders

class EventSearchResultsSpec: QuickSpec {
    var subject: EventSearchResult!

    var mondayEventA = TestUtils.eventWithStartDate(NSDate(timeIntervalSince1970: 1446430652), timeZone: "GMT")
    var mondayEventB = TestUtils.eventWithStartDate(NSDate(timeIntervalSince1970: 1446524252), timeZone: "PST")
    var wednesdayEvent = TestUtils.eventWithStartDate(NSDate(timeIntervalSince1970: 1446699074), timeZone: "PST")

    override func spec() {
        beforeEach {
            self.subject = EventSearchResult(searchCentroid: CLLocation(), events: [self.wednesdayEvent, self.mondayEventA, self.mondayEventB])
        }

        describe("EventSearchResults") {
            describe("getting the unique days in a search result") {
                it("returns a date (in the local timezone) per unique day (respective of event timezones) in the search result, in ascending order") {
                    let dateComponents = NSDateComponents()
                    dateComponents.year = 2015
                    dateComponents.month = 11
                    dateComponents.day = 2
                    let calendar = NSCalendar.currentCalendar()

                    let monday = calendar.dateFromComponents(dateComponents)!
                    dateComponents.day = 4
                    let wednesday = calendar.dateFromComponents(dateComponents)!
                    let expectedDays = [monday, wednesday]

                    let uniqueDaysInLocalTimeZone = self.subject.uniqueDaysInLocalTimeZone

                    expect(uniqueDaysInLocalTimeZone()).to(equal(expectedDays))
                }
            }

            describe("getting the events with a given day index") {
                it("returns the events that are within that day index") {
                    let mondayEvents = self.subject.eventsWithDayIndex(0)
                    expect(mondayEvents.count).to(equal(2))
                    expect(mondayEvents.first).to(beIdenticalTo(self.mondayEventA))
                    expect(mondayEvents.last).to(beIdenticalTo(self.mondayEventB))

                    let wednesdayEvents = self.subject.eventsWithDayIndex(1)
                    expect(wednesdayEvents.count).to(equal(1))
                    expect(wednesdayEvents.first).to(beIdenticalTo(self.wednesdayEvent))
                }
            }
        }
    }
}
