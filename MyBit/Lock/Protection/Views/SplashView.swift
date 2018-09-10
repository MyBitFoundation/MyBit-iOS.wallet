// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class SplashView: UIView {
    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = .white
        let logoImageView = UIImageView(image: R.image.myBitTokenIcon())
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 150),
            logoImageView.heightAnchor.constraint(equalToConstant: 150),
        ])
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
