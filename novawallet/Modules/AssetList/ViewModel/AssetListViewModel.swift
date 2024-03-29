import Foundation
import SubstrateSdk

enum LoadableViewModelState<T> {
    case loading
    case cached(value: T)
    case loaded(value: T)

    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        case .cached, .loaded:
            return false
        }
    }
}

enum ValueDirection<T> {
    case increase(value: T)
    case decrease(value: T)
}

struct AssetListHeaderViewModel {
    let title: String
    let amount: LoadableViewModelState<String>
    let locksAmount: String?
    let walletSwitch: WalletSwitchViewModel
}

struct AssetListNftsViewModel {
    let totalCount: LoadableViewModelState<String>
    let mediaViewModels: [NftMediaViewModelProtocol]
}

struct AssetPriceViewModel {
    let amount: String
    let change: ValueDirection<String>
}

enum AssetListGroupState {
    case empty
    case list(groups: [AssetListGroupViewModel])

    var isEmpty: Bool {
        switch self {
        case .empty:
            return true
        case .list:
            return false
        }
    }

    var groups: [AssetListGroupViewModel] {
        switch self {
        case .empty:
            return []
        case let .list(groups):
            return groups
        }
    }
}

struct AssetListGroupViewModel {
    let networkName: String
    let amount: LoadableViewModelState<String>
    let icon: ImageViewModelProtocol?
    let assets: [AssetListAssetViewModel]
}

struct AssetListAssetViewModel {
    let chainAssetId: ChainAssetId
    let tokenName: String
    let icon: ImageViewModelProtocol?
    let price: LoadableViewModelState<AssetPriceViewModel>
    let balanceAmount: LoadableViewModelState<String>
    let balanceValue: LoadableViewModelState<String>
}

extension LoadableViewModelState: Hashable, Equatable where T == String {}
