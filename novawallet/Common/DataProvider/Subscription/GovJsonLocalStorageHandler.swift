import Foundation

protocol GovJsonLocalStorageHandler {
    func handleDelegatesMetadata(
        result: Result<[GovernanceDelegateMetadataRemote], Error>,
        chain: ChainModel
    )
}

extension GovJsonLocalStorageHandler {
    func handleDelegatesMetadata(
        result _: Result<[GovernanceDelegateMetadataRemote], Error>,
        chain _: ChainModel
    ) {}
}
