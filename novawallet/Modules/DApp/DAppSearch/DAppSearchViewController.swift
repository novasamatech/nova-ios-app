import UIKit
import SoraFoundation

final class DAppSearchViewController: UIViewController, ViewHolder {
    typealias RootViewType = DAppSearchViewLayout

    let presenter: DAppSearchPresenterProtocol

    init(presenter: DAppSearchPresenterProtocol, localizationManager: LocalizationManagerProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        self.localizationManager = localizationManager
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = DAppSearchViewLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSearchBar()
        setupLocalization()

        presenter.setup()
    }

    private func setupLocalization() {
        rootView.searchBar.textField.placeholder = "Search by name or enter URL"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        rootView.searchBar.textField.becomeFirstResponder()
    }

    private func setupSearchBar() {
        navigationItem.titleView = rootView.searchBar

        rootView.searchBar.textField.delegate = self
    }
}

extension DAppSearchViewController: DAppSearchViewProtocol {
    func didReceive(initialQuery: String) {
        rootView.searchBar.textField.text = initialQuery
    }
}

extension DAppSearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let input = textField.text else {
            return false
        }

        presenter.activateSearch(for: input)

        return true
    }
}

extension DAppSearchViewController: Localizable {
    func applyLocalization() {
        if isViewLoaded {
            setupLocalization()
        }
    }
}