// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import APIKit
import JSONRPCKit
import StatefulViewController
import Result
import TrustCore
import RealmSwift

protocol TransactionsViewControllerDelegate: class {
    func didPressSend(in viewController: TransactionsViewController)
    func didPressRequest(in viewController: TransactionsViewController)
    func didPressTransaction(transaction: Transaction, in viewController: TransactionsViewController)
    func didPressDeposit(for account: Wallet, sender: UIView, in viewController: TransactionsViewController)
}

class TransactionsViewController: UIViewController {

    var emptyLabel = UIView()
    
    var loadingFlag = true
    var currentPage : Int = 0
    var isLoadingList : Bool = false
    
    var viewModel: TransactionsViewModel
    let account: Wallet
    let tableView = TransactionsTableView()
    let refreshControl = UIRefreshControl()
    weak var delegate: TransactionsViewControllerDelegate?
    var timer: Timer?
    var updateTransactionsTimer: Timer?
    let session: WalletSession
    let insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    init(
        account: Wallet,
        session: WalletSession,
        viewModel: TransactionsViewModel
    ) {
        self.account = account
        self.session = session
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = TransactionsViewModel.backgroundColor
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.tableFooterView = UIView()
        tableView.register(TransactionViewCell.self, forCellReuseIdentifier: TransactionViewCell.identifier)
        
        let top = NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: tableView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        let left = NSLayoutConstraint(item: tableView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: tableView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: 0)
        
        view.addConstraints([top, bottom, left, right])

        refreshControl.backgroundColor = TransactionsViewModel.backgroundColor
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        errorView = ErrorView(insets: insets, onRetry: { [weak self] in
            self?.startLoading()
            self?.viewModel.fetch()
        })
        loadingView = LoadingView(insets: insets)
        emptyLabel = TransactionsEmptyView(insets: insets)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView()
        tableView.addSubview(emptyLabel)
        emptyLabel.isHidden = true
        emptyView?.isUserInteractionEnabled = false

        navigationItem.title = viewModel.title
        runScheduledTimers()
        NotificationCenter.default.addObserver(self, selector: #selector(TransactionsViewController.stopTimers), name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TransactionsViewController.restartTimers), name: .UIApplicationDidBecomeActive, object: nil)

        transactionsObservation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: emptyLabel, attribute: .centerX, relatedBy: .equal, toItem: tableView, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: emptyLabel, attribute: .centerY, relatedBy: .equal, toItem: tableView, attribute: .centerY, multiplier: 1, constant: 0)])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshControl.endRefreshing()
        fetch()
    }

    private func transactionsObservation() {
        viewModel.transactionsUpdateObservation { [weak self] in
            guard let `self` = self else { return }
            self.tableView.reloadData()
            self.endLoading()
            self.refreshControl.endRefreshing()
            self.tabBarItem.badgeValue = self.viewModel.badgeValue
            if self.viewModel.numberOfSections != 0 {
                self.emptyLabel.isHidden = true
            } else {
                self.emptyLabel.isHidden = false
            }
        }
    }

    private func loadMoreItemsForList() {
        currentPage += 1
        fetch(page: currentPage)
    }

    @objc func pullToRefresh() {
        loadingFlag = false
        refreshControl.beginRefreshing()
        fetch()
    }

    func fetch(page: Int? = nil) {
        startLoading()
        viewModel.fetch(page: page ?? 0) { [weak self] in
            self?.isLoadingList = false
            self?.endLoading()
            self?.refreshControl.endRefreshing()
        }
    }

    @objc func send() {
        delegate?.didPressSend(in: self)
    }

    @objc func request() {
        delegate?.didPressRequest(in: self)
    }

    func showDeposit(_ sender: UIButton) {
        delegate?.didPressDeposit(for: account, sender: sender, in: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func stopTimers() {
        timer?.invalidate()
        timer = nil
        updateTransactionsTimer?.invalidate()
        updateTransactionsTimer = nil
        viewModel.invalidateTransactionsObservation()
    }

    @objc func restartTimers() {
        runScheduledTimers()
        transactionsObservation()
    }

    private func runScheduledTimers() {
        guard timer == nil, updateTransactionsTimer == nil else {
            return
        }
        timer = Timer.scheduledTimer(timeInterval: 5, target: BlockOperation { [weak self] in
            self?.viewModel.fetchPending()
        }, selector: #selector(Operation.main), userInfo: nil, repeats: true)
        updateTransactionsTimer = Timer.scheduledTimer(timeInterval: 15, target: BlockOperation { [weak self] in
            self?.viewModel.fetchTransactions()
        }, selector: #selector(Operation.main), userInfo: nil, repeats: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        viewModel.invalidateTransactionsObservation()
    }
}

extension TransactionsViewController: StatefulViewController {
    func hasContent() -> Bool {
        if loadingFlag == true {
            return viewModel.hasContent
        } else {
            loadingFlag = true
            return true
        }
    }
}

extension TransactionsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true )
        delegate?.didPressTransaction(transaction: viewModel.item(for: indexPath.row, section: indexPath.section), in: self)
    }
}

extension TransactionsViewController: UITableViewDataSource {
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
}
