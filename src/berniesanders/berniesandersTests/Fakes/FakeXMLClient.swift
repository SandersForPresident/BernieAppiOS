import berniesanders
import Foundation
import KSDeferred

class FakeXMLClient: berniesanders.XMLClient {
    private (set) var deferredsByURL = [NSURL: KSDeferred]()
    
    func fetchXMLDocumentWithURL(url: NSURL) -> KSPromise {
        var deferred =  KSDeferred.defer()
        self.deferredsByURL[url] = deferred
        return deferred.promise
    }
}