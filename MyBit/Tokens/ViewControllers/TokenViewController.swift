// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import StatefulViewController

protocol TokenViewControllerDelegate: class {
    func didPressRequest(for token: TokenObject, in controller: UIViewController)
    func didPressSend(for token: TokenObject, in controller: UIViewController)
    func didPress(transaction: Transaction, in controller: UIViewController)
}

class TokenViewController: UIViewController {

    var currentPage : Int = 0
    var isLoadingList : Bool = false
    
    private let refreshControl = UIRefreshControl()
    
    private var tableView = TransactionsTableView()

    private lazy var header: TokenHeaderView = {
        let view = TokenHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 264))
        return view
    }()

    private let insets = UIEdgeInsets(top: 348, left: 0, bottom: 0, right: 0)

    private var emptyLabel = UIView()
    
    private var viewModel: TokenViewModel

    weak var delegate: TokenViewControllerDelegate?

    init(viewModel: TokenViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)

        self.viewModel.delegate = self
        
        navigationItem.title = viewModel.title
        view.backgroundColor = .white

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = header
        tableView.register(TransactionViewCell.self, forCellReuseIdentifier: TransactionViewCell.identifier)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        ])

        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableView.addSubview(refreshControl)

        header.buttonsView.requestButton.addTarget(self, action: #selector(request), for: .touchUpInside)
        header.buttonsView.sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)
        updateHeader()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        observToken()
        observTransactions()
        configTableViewStates()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupInitialViewState()
        viewModel.fetch()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let topIndention = (tableView.frame.height - header.frame.height) / 2
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: emptyLabel, attribute: .top, relatedBy: .equal, toItem: header, attribute: .bottom, multiplier: 1, constant: topIndention),
            NSLayoutConstraint(item: emptyLabel, attribute: .centerX, relatedBy: .equal, toItem: tableView, attribute: .centerX, multiplier: 1, constant: 1),
            NSLayoutConstraint(item: emptyLabel, attribute: .width, relatedBy: .equal, toItem: tableView, attribute: .width, multiplier: 1, constant: 1)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func observToken() {
        viewModel.tokenObservation { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.updateHeader()
        }
    }

    private func loadMoreItemsForList() {
        currentPage += 1
        fetch(page: currentPage)
    }
    
    private func observTransactions() {
        viewModel.transactionObservation { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.isLoadingList = false
            self?.tableView.reloadData()
            if self?.viewModel.numberOfSections != 0 {
                self?.emptyLabel.isHidden = true
            } else {
                self?.emptyLabel.isHidden = false
            }
        }
    }

    private func updateHeader() {
        header.imageView.image = viewModel.imagePlaceholder
        
        header.amountLabel.text = viewModel.amount
        header.amountLabel.font = viewModel.amountFont
        header.amountLabel.textColor = viewModel.amountTextColor

        header.fiatAmountLabel.text = viewModel.totalFiatAmount
        header.fiatAmountLabel.font = viewModel.fiatAmountFont
        header.fiatAmountLabel.textColor = viewModel.fiatAmountTextColor

//        header.currencyAmountLabel.text = viewModel.currencyAmount
//        header.currencyAmountLabel.textColor = viewModel.currencyAmountTextColor
//        header.currencyAmountLabel.font = viewModel.currencyAmountFont
//
        header.percentChange.text = viewModel.percentChange
        header.percentChange.textColor = viewModel.percentChangeColor
        header.percentChange.font = viewModel.percentChangeFont
    }

    func fetch(page: Int = 0) {
        refreshControl.beginRefreshing()
        viewModel.fetch(page: page)
    }
    
    @objc func pullToRefresh() {
        refreshControl.beginRefreshing()
        viewModel.fetch()
    }

    @objc func send() {
        delegate?.didPressSend(for: viewModel.token, in: self)
    }

    @objc func request() {
        delegate?.didPressRequest(for: viewModel.token, in: self)
    }

    deinit {
        viewModel.invalidateObservers()
    }

    private func configTableViewStates() {
        errorView = ErrorView(insets: insets, onRetry: { [weak self] in
            self?.viewModel.fetch()
        })
        loadingView = LoadingView(insets: insets)
        emptyLabel = TransactionsEmptyView(insets: insets)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView()
        tableView.addSubview(emptyLabel)
        emptyLabel.isHidden = true
    }
}

extension TokenViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionViewCell.identifier, for: indexPath) as! TransactionViewCell
        cell.configure(viewModel: viewModel.cellViewModel(for: indexPath))
        let lastSection = viewModel.numberOfSections - 1
        let lastObject = viewModel.numberOfItems(for: indexPath.section) - 1
        if indexPath.section == lastSection && indexPath.row == lastObject  && !isLoadingList {
            self.isLoadingList = true
            self.loadMoreItemsForList()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(for: section)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return viewModel.hederView(for: section)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return StyleLayout.TableView.heightForHeaderInSection
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didPress(transaction: viewModel.item(for: indexPath.row, section: indexPath.section), in: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension TokenViewController: StatefulViewController {
    
    func hasContent() -> Bool {
        return viewModel.hasContent()
    }
}

extension TokenViewController: TokenViewModelDelegate {
    
    func stopRefresh() {
        
        self.refreshControl.endRefreshing()
    }
}
