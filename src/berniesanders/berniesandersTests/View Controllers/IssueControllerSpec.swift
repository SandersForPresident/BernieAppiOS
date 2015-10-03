import UIKit
import Quick
import Nimble
import berniesanders

class IssueFakeTheme : FakeTheme {
    override func issueTitleFont() -> UIFont {
        return UIFont.italicSystemFontOfSize(13)
    }
    
    override func issueTitleColor() -> UIColor {
        return UIColor.brownColor()
    }
    
    override func issueBodyFont() -> UIFont {
        return UIFont.systemFontOfSize(3)
    }
    
    override func issueBodyColor() -> UIColor {
        return UIColor.yellowColor()
    }
    
    override func defaultBackgroundColor() -> UIColor {
        return UIColor.orangeColor()
    }
}


class IssueControllerSpec : QuickSpec {
    var subject : IssueController!
    var imageRepository : FakeImageRepository!
    var analyticsService: FakeAnalyticsService!
    let issue = TestUtils.issue()

    override func spec() {
        context("with a standard issue") {
            beforeEach {
                self.imageRepository = FakeImageRepository()
                self.analyticsService = FakeAnalyticsService()
                
                self.subject = IssueController(
                    issue: self.issue,
                    imageRepository: self.imageRepository,
                    analyticsService: self.analyticsService,
                    theme: IssueFakeTheme())
            }
            
            it("should hide the tab bar when pushed") {
                expect(self.subject.hidesBottomBarWhenPushed).to(beTrue())
            }
            
            describe("when the view loads") {
                beforeEach {
                    self.subject.view.layoutIfNeeded()
                }
                
                it("has a share button on the navigation item") {
                    var shareBarButtonItem = self.subject.navigationItem.rightBarButtonItem!
                    expect(shareBarButtonItem.valueForKey("systemItem") as? Int).to(equal(UIBarButtonSystemItem.Action.rawValue))
                }
                
                it("sets up the body text view not to be editable") {
                    expect(self.subject.bodyTextView.editable).to(beFalse())
                }
                
                describe("tapping on the share button") {
                    beforeEach {
                        self.subject.navigationItem.rightBarButtonItem!.tap()
                    }
                    
                    it("should present an activity view controller for sharing the story URL") {
                        let activityViewControler = self.subject.presentedViewController as! UIActivityViewController
                        let activityItems = activityViewControler.activityItems()
                        
                        expect(activityItems.count).to(equal(1))
                        expect(activityItems.first as? NSURL).to(beIdenticalTo(self.issue.URL))
                    }
                    
                    it("logs that the user tapped share") {
                        expect(self.analyticsService.lastCustomEventName).to(equal("Tapped 'Share' on Issue"))
                        let expectedAttributes = [ AnalyticsServiceConstants.contentIDKey: self.issue.URL.absoluteString!]
                        expect(self.analyticsService.lastCustomEventAttributes! as? [String: String]).to(equal(expectedAttributes))
                    }
                    
                    context("and the user completes the share succesfully") {
                        it("tracks the share via the analytics service") {
                            let activityViewControler = self.subject.presentedViewController as! UIActivityViewController
                            activityViewControler.completionWithItemsHandler!("Some activity", true, nil, nil)
                            
                            expect(self.analyticsService.lastShareActivityType).to(equal("Some activity"))
                            expect(self.analyticsService.lastShareContentName).to(equal(self.issue.title))
                            expect(self.analyticsService.lastShareContentType).to(equal(AnalyticsServiceContentType.Issue))
                            expect(self.analyticsService.lastShareID).to(equal(self.issue.URL.absoluteString))
                        }
                    }
                    
                    context("and the user cancels the share") {
                        it("tracks the share cancellation via the analytics service") {
                            let activityViewControler = self.subject.presentedViewController as! UIActivityViewController
                            activityViewControler.completionWithItemsHandler!(nil, false, nil, nil)
                            
                            expect(self.analyticsService.lastCustomEventName).to(equal("Cancelled share of Issue"))
                            let expectedAttributes = [ AnalyticsServiceConstants.contentIDKey: self.issue.URL.absoluteString!]
                            expect(self.analyticsService.lastCustomEventAttributes! as? [String: String]).to(equal(expectedAttributes))
                        }
                    }
                    
                    context("and there is an error when sharing") {
                        it("tracks the error via the analytics service") {
                            let expectedError = NSError(domain: "a", code: 0, userInfo: nil)
                            let activityViewControler = self.subject.presentedViewController as! UIActivityViewController
                            activityViewControler.completionWithItemsHandler!("asdf", true, nil, expectedError)
                            
                            expect(self.analyticsService.lastError).to(beIdenticalTo(expectedError))
                            expect(self.analyticsService.lastErrorContext).to(equal("Failed to share Issue"))
                        }
                    }
                }
                
                it("has a scroll view containing the UI elements") {
                    expect(self.subject.view.subviews.count).to(equal(1))
                    var scrollView = self.subject.view.subviews.first as! UIScrollView
                    
                    expect(scrollView).to(beAnInstanceOf(UIScrollView.self))
                    expect(scrollView.subviews.count).to(equal(1))
                    
                    var containerView = scrollView.subviews.first as! UIView
                    
                    expect(containerView.subviews.count).to(equal(3))
                    
                    var containerViewSubViews = containerView.subviews as! [UIView]
                    
                    expect(contains(containerViewSubViews, self.subject.titleLabel)).to(beTrue())
                    expect(contains(containerViewSubViews, self.subject.bodyTextView)).to(beTrue())
                    expect(contains(containerViewSubViews, self.subject.issueImageView)).to(beTrue())
                }
                
                it("styles the views according to the theme") {
                    expect(self.subject.view.backgroundColor).to(equal(UIColor.orangeColor()))
                    expect(self.subject.titleLabel.font).to(equal(UIFont.italicSystemFontOfSize(13)))
                    expect(self.subject.titleLabel.textColor).to(equal(UIColor.brownColor()))
                    expect(self.subject.bodyTextView.font).to(equal(UIFont.systemFontOfSize(3)))
                    expect(self.subject.bodyTextView.textColor).to(equal(UIColor.yellowColor()))
                }
                
                it("displays the title from the issue") {
                    expect(self.subject.titleLabel.text).to(equal("An issue title made by TestUtils"))
                }
                
                it("displays the issue body") {
                    expect(self.subject.bodyTextView.text).to(equal("An issue body made by TestUtils"))
                }
                
                it("makes a request for the story's image") {
                    expect(self.imageRepository.lastReceivedURL).to(beIdenticalTo(self.issue.imageURL))
                }
                
                context("when the request for the story's image succeeds") {
                    it("displays the image") {
                        var issueImage = TestUtils.testImageNamed("bernie", type: "jpg")
                        
                        self.imageRepository.lastRequestDeferred.resolveWithValue(issueImage)
                        
                        var expectedImageData = UIImagePNGRepresentation(issueImage)
                        var storyImageData = UIImagePNGRepresentation(self.subject.issueImageView.image)
                        
                        expect(storyImageData).to(equal(expectedImageData))
                    }
                }
                
                context("when the request for the story's image fails") {
                    it("removes the image view from the container") {
                        self.imageRepository.lastRequestDeferred.rejectWithError(nil)
                        var scrollView = self.subject.view.subviews.first as! UIScrollView
                        var containerView = scrollView.subviews.first as! UIView
                        var containerViewSubViews = containerView.subviews as! [UIView]
                        
                        expect(contains(containerViewSubViews, self.subject.issueImageView)).to(beFalse())
                    }
                }
            }
            
            context("with an issue that lacks an image") {
                beforeEach {
                    let issue = Issue(title: "Some issue", body: "body", imageURL: nil, URL: NSURL(string: "http://b.com")!)
                    
                    self.subject = IssueController(
                        issue: issue,
                        imageRepository: self.imageRepository,
                        analyticsService: self.analyticsService,
                        theme: IssueFakeTheme())
               
                
                    self.subject.view.layoutIfNeeded()
                }
                
                it("should not make a request for the story's image") {
                    expect(self.imageRepository.imageRequested).to(beFalse())
                }
                
                it("removes the image view from the container") {
                    var scrollView = self.subject.view.subviews.first as! UIScrollView
                    var containerView = scrollView.subviews.first as! UIView
                    var containerViewSubViews = containerView.subviews as! [UIView]
                    
                    expect(contains(containerViewSubViews, self.subject.issueImageView)).to(beFalse())
                }
            }
        }
    }
}
