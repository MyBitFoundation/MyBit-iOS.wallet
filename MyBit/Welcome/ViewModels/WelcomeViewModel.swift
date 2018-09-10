// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit

struct WelcomeViewModel {

    var title: String {
        return "Welcome"
    }

    var backgroundColor: UIColor {
        return .white
    }

    var pageIndicatorTintColor: UIColor {
        return Colors.lightGray
    }

    var currentPageIndicatorTintColor: UIColor {
        return Colors.blue
    }

    var numberOfPages = 0
    var currentPage = 0
}
