import XCTest
@testable import novawallet
import RobinHood

class EthereumBaseIntegrationTests: XCTestCase {
    func testSubsribeBalance() throws {
        // given

        let accountId = try Data(hexString: "0x2e042c2F97f0952E6fa3D68CD6D65F7201c2de84")
        let chainId = "91bc6e169807aaa54802737e1c504b2577d4fafedd5a02c10293b1cd60e39527"
        let assetId: AssetModel.Id = 0

        let logger = Logger.shared
        let chainStorageFacade = SubstrateStorageTestFacade()
        let chainRegistry = ChainRegistryFacade.setupForIntegrationTest(with: chainStorageFacade)
        let repository = SubstrateRepositoryFactory(storageFacade: chainStorageFacade)
            .createChainStorageItemRepository()
        let operationManager = OperationManager()

        let walletService = WalletRemoteSubscriptionService(
            chainRegistry: chainRegistry,
            repository: repository,
            syncOperationManager: operationManager,
            repositoryOperationManager: operationManager,
            logger: Logger.shared
        )

        guard let subscriptionId = walletService.attachToAccountInfo(
            of: accountId,
            chainId: chainId,
            chainFormat: .ethereum,
            queue: nil,
            closure: nil,
            subscriptionHandlingFactory: nil
        ) else {
            XCTFail("Can't subscribe to remote storage")
            return
        }

        let walletLocalSubscriptionFactory = WalletLocalSubscriptionFactory(
            chainRegistry: chainRegistry,
            storageFacade: chainStorageFacade,
            operationManager: operationManager,
            logger: Logger.shared
        )

        let balanceProvider = try walletLocalSubscriptionFactory.getAssetBalanceProvider(
            for: accountId,
            chainId: chainId,
            assetId: assetId
        )

        let expectation = XCTestExpectation()

        let updateClosure: ([DataProviderChange<AssetBalance>]) -> Void = { changes in
            guard let balance = changes.reduceToLastChange() else {
                return
            }

            logger.info("Available: \(balance.transferable)")

            expectation.fulfill()
        }

        let failureClosure: (Error) -> Void = { error in
            XCTFail("Unexpected error \(error)")
        }

        balanceProvider.addObserver(
            self,
            deliverOn: .global(),
            executing: updateClosure,
            failing: failureClosure,
            options: StreamableProviderObserverOptions(
                alwaysNotifyOnRefresh: false,
                waitsInProgressSyncOnAdd: false,
                initialSize: 0,
                refreshWhenEmpty: true
            )
        )

        wait(for: [expectation], timeout: 20.0)

        walletService.detachFromAccountInfo(
            for: subscriptionId,
            accountId: accountId,
            chainId: chainId,
            queue: nil,
            closure: nil
        )
    }

    func testTransactionReceiptFetch() {
        // given

        let chainId = "fe58ea77779b7abda7da4ec526d14db9b1e9cd40a217c34892af80a9b332b76d"
        let transactionHash = "0x6350478650f0ad0771ddd5895c5bc9c86d575d047cd9a095ebbb8a8f029a39f6"

        // when

        do {
            let receipt = try fetchTransactionReceipt(for: chainId, txHash: transactionHash)

            XCTAssertNotNil(receipt?.fee)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testTransactionReceiptNullForInvalidHash() {
        // given

        let chainId = "fe58ea77779b7abda7da4ec526d14db9b1e9cd40a217c34892af80a9b332b76d"
        let transactionHash = "0x6350478650f0ad1771ddd5895c5bc9c86d575d047cd9a095ebbb8a8f029a39f6"

        // when

        do {
            let receipt = try fetchTransactionReceipt(for: chainId, txHash: transactionHash)

            XCTAssertNil(receipt)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func fetchTransactionReceipt(for chainId: ChainModel.Id, txHash: String) throws -> EthereumTransactionReceipt? {
        let chainStorageFacade = SubstrateStorageTestFacade()
        let chainRegistry = ChainRegistryFacade.setupForIntegrationTest(with: chainStorageFacade)

        guard let connection = chainRegistry.getConnection(for: chainId) else {
            throw ChainRegistryError.connectionUnavailable
        }

        let operationFactory = EvmWebSocketOperationFactory(connection: connection)

        let operation = operationFactory.createTransactionReceiptOperation(for: txHash)

        OperationQueue().addOperations([operation], waitUntilFinished: true)

        return try operation.extractNoCancellableResultData()
    }
}
