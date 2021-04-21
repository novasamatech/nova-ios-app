import UIKit
import SoraFoundation

final class StakingPayoutConfirmationViewController: UIViewController, ViewHolder {
    typealias RootViewType = StakingPayoutConfirmationViewLayout

    let presenter: StakingPayoutConfirmationPresenterProtocol

    private var feeViewModel: LocalizableResource<BalanceViewModelProtocol>?
    private var viewModel: [LocalizableResource<RewardConfirmRow>] = []

    init(
        presenter: StakingPayoutConfirmationPresenterProtocol,
        localizationManager: LocalizationManagerProtocol?
    ) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
        self.localizationManager = localizationManager
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = StakingPayoutConfirmationViewLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupInitialFeeView()
        applyLocalization()
        setupTable()
        presenter.setup()
    }

    // MARK: - Private functions

    @objc private func confirmAction() {
        presenter.proceed()
    }

    private func setupInitialFeeView() {
        let locale = localizationManager?.selectedLocale ?? Locale.current

        let viewModel = TransferConfirmAccessoryViewModel(
            title: R.string.localizable.commonNetworkFee(preferredLanguages: locale.rLanguages),
            icon: nil,
            action: R.string.localizable.commonConfirm(preferredLanguages: locale.rLanguages),
            numberOfLines: 1,
            amount: "",
            shouldAllowAction: false
        )
        rootView.transferConfirmView.bind(viewModel: viewModel)

        if #available(iOS 14, *) {
            rootView.transferConfirmView.actionButton.addAction(UIAction(title: "", handler: { [weak self] _ in
                self?.confirmAction()
            }), for: .touchUpInside)
        } else {
            rootView.transferConfirmView.actionButton
                .addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
        }
    }

    private func setupTable() {
        rootView.tableView.registerClassesForCell([
            AccountInfoTableViewCell.self,
            StakingPayoutConfirmRewardTableCell.self
        ])

        rootView.tableView.dataSource = self
        rootView.tableView.allowsSelection = false
    }
}

// MARK: - Localizible

extension StakingPayoutConfirmationViewController: Localizable {
    private func setupLocalization() {
        let locale = localizationManager?.selectedLocale ?? Locale.current

        setupTitleLocalization(locale)
        setupTranformViewLocalization(locale)
    }

    private func setupTitleLocalization(_ locale: Locale) {
        title = R.string.localizable.commonConfirmTitle(preferredLanguages: locale.rLanguages)
    }

    private func setupTranformViewLocalization(_ locale: Locale) {
        guard let feeViewModel = feeViewModel?.value(for: locale) else { return }

        let feeString = feeViewModel.amount + "  " + (feeViewModel.price ?? "")

        let viewModel = TransferConfirmAccessoryViewModel(
            title: R.string.localizable.commonNetworkFee(preferredLanguages: locale.rLanguages),
            icon: nil,
            action: R.string.localizable.commonConfirm(preferredLanguages: locale.rLanguages),
            numberOfLines: 1,
            amount: feeString,
            shouldAllowAction: true
        )
        rootView.transferConfirmView.bind(viewModel: viewModel)
    }

    func applyLocalization() {
        if isViewLoaded {
            setupLocalization()
            rootView.tableView.reloadData()
            view.setNeedsLayout()
        }
    }
}

// MARK: - UITableViewDataSource

extension StakingPayoutConfirmationViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        viewModel.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let locale = localizationManager?.selectedLocale ?? Locale.current

        switch viewModel[indexPath.row].value(for: locale) {
        case let .rewardAmountViewModel(viewModel):
            let cell = tableView.dequeueReusableCellWithType(
                StakingPayoutConfirmRewardTableCell.self)!
            cell.bind(
                model: viewModel
            )
            return cell

        case let .accountInfo(viewModel):
            let cell = tableView.dequeueReusableCellWithType(
                AccountInfoTableViewCell.self)!
            cell.bind(model: viewModel)
            return cell

        default:
            fatalError()
        }
    }
}

// MARK: - StakingPayoutConfirmationViewProtocol

extension StakingPayoutConfirmationViewController: StakingPayoutConfirmationViewProtocol {
    func didReceive(feeViewModel: LocalizableResource<BalanceViewModelProtocol>?) {
        self.feeViewModel = feeViewModel
        let locale = localizationManager?.selectedLocale ?? Locale.current
        setupTranformViewLocalization(locale)
    }

    func didRecieve(viewModel: [LocalizableResource<RewardConfirmRow>]) {
        self.viewModel = viewModel
    }
}
