// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum DeteilsViewType: Int {
    case tokens
}

class WalletViewController: UIViewController {

    var tokensViewController: TokensViewController

    init(
        tokensViewController: TokensViewController
    ) {
        self.tokensViewController = tokensViewController
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = NSLocalizedString("wallet.navigation.title", value: "Wallet", comment: "")
        setupView()
    }

    private func setupView() {
        updateView()
    }

    private func updateView() {
        add(asChildViewController: tokensViewController)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
