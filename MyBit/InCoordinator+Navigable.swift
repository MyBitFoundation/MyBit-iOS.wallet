// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import URLNavigator

extension InCoordinator: URLNavigable {
    func register(with navigator: Navigator) {
        navigator.handle(URLSchemes.browser) { url, _, _ in
            guard let target = url.queryParameters["target"],
                let _ = URL(string: target) else {
                    return false
            }
            return true
        }

        navigator.handle(URLSchemes.signTransaction) { _, _, _ in
            //parse url
            self.handleTrustSDK()
            return true
        }

        navigator.handle(URLSchemes.signMessage) { _, _, _ in
            //parse url
            self.handleTrustSDK()
            return true
        }
    }
}
