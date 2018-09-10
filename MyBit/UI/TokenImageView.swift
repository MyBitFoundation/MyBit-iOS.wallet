// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class TokenImageView: UIImageView {

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.size.width / 2.0
        layer.borderColor = Colors.bordersGray.cgColor
        layer.borderWidth = 0.5
        layer.masksToBounds = false
        contentMode = .scaleAspectFit
        clipsToBounds = true
    }
}
