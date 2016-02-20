import Quick
import Nimble

@testable import Connect

class StockActionsTableViewCellPresenterSpec: QuickSpec {
    override func spec() {
        describe("StockActionsTableViewCellPresenter") {
            var theme: FakeActionsTableViewPresenterTheme!
            var tableView: UITableView!
            var subject: ActionsTableViewCellPresenter!

            beforeEach {
                theme = FakeActionsTableViewPresenterTheme()
                tableView = UITableView()
                subject = StockActionsTableViewCellPresenter(theme: theme)
            }

            describe("presenting an action alert row") {
                describe("when the table view has registered the correct cell type for dequeueing") {
                    var actionAlert: ActionAlert!

                    beforeEach {
                        actionAlert = TestUtils.actionAlert("Get to da choppa!")
                        tableView.registerClass(ActionAlertTableViewCell.self, forCellReuseIdentifier: "actionAlertCell")
                    }

                    it("style the cell using the theme") {
                        let cell = subject.presentActionAlertTableViewCell(actionAlert, tableView: tableView) as! ActionAlertTableViewCell

                        expect(cell.backgroundColor).to(equal(UIColor.redColor()))
                        expect(cell.titleLabel.textColor).to(equal(UIColor.purpleColor()))
                        expect(cell.titleLabel.font).to(equal(UIFont.systemFontOfSize(111)))
                        expect(cell.disclosureView.color).to(equal(UIColor.orangeColor()))
                    }

                    it("sets the title from the action alert") {
                        let cell = subject.presentActionAlertTableViewCell(actionAlert, tableView: tableView) as! ActionAlertTableViewCell

                        expect(cell.titleLabel.text).to(equal("Get to da choppa!"))
                    }

                }

                describe("when the table view has not registered the correct cell type for dequeueing") {
                    it("returns a plain ol' UITableViewCell") {
                        let actionAlert = TestUtils.actionAlert()
                        let cell = subject.presentActionAlertTableViewCell(actionAlert, tableView: tableView)
                        expect(cell).to(beAnInstanceOf(UITableViewCell.self))
                    }
                }
            }
        }
    }
}

private class FakeActionsTableViewPresenterTheme: FakeTheme {
    private override func actionsTitleFont() -> UIFont {
        return UIFont.systemFontOfSize(111)
    }

    private override func actionsTitleTextColor() -> UIColor {
        return UIColor.purpleColor()
    }

    private override func defaultDisclosureColor() -> UIColor {
        return UIColor.orangeColor()
    }

    private override func defaultTableCellBackgroundColor() -> UIColor {
        return UIColor.redColor()
    }
}