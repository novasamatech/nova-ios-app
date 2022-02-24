import Foundation
import SubstrateSdk
import RobinHood

final class UniquesSyncService: BaseNftSyncService {
    let chainRegistry: ChainRegistryProtocol
    let ownerId: AccountId
    let chainId: ChainModel.Id

    init(
        chainRegistry: ChainRegistryProtocol,
        ownerId: AccountId,
        chainId: ChainModel.Id,
        repository: AnyDataProviderRepository<NftModel>,
        operationQueue: OperationQueue,
        retryStrategy: ReconnectionStrategyProtocol = ExponentialReconnection(),
        logger: LoggerProtocol? = Logger.shared
    ) {
        self.chainRegistry = chainRegistry
        self.ownerId = ownerId
        self.chainId = chainId

        super.init(
            repository: repository,
            operationQueue: operationQueue,
            retryStrategy: retryStrategy,
            logger: logger
        )
    }

    private lazy var operationFactory: UniquesOperationFactoryProtocol = UniquesOperationFactory()

    private func createRemoteMapOperation(
        dependingOn accountKeysWrapper: CompoundOperationWrapper<[UniquesAccountKey]>,
        instanceWrapper: CompoundOperationWrapper<[UInt32: UniquesInstanceMetadata]>,
        chainId: String,
        ownerId: AccountId
    ) -> BaseOperation<[NftModel]> {
        ClosureOperation<[NftModel]> {
            let accountKeys = try accountKeysWrapper.targetOperation.extractNoCancellableResultData()
            let instanceStore = try instanceWrapper.targetOperation.extractNoCancellableResultData()

            return accountKeys.map { accountKey in
                let instanceMetadata = instanceStore[accountKey.instanceId]
                let identifier = NftModel.uniquesIdentifier(
                    for: chainId,
                    classId: accountKey.classId,
                    instanceId: accountKey.instanceId
                )

                return NftModel(
                    identifier: identifier,
                    type: NftType.uniques.rawValue,
                    chainId: chainId,
                    ownerId: ownerId,
                    metadata: instanceMetadata?.data
                )
            }
        }
    }

    override func createRemoteFetchWrapper() -> CompoundOperationWrapper<[NftModel]> {
        guard let connection = chainRegistry.getConnection(for: chainId) else {
            return CompoundOperationWrapper.createWithError(ChainRegistryError.connectionUnavailable)
        }

        guard let runtimeProvider = chainRegistry.getRuntimeProvider(for: chainId) else {
            return CompoundOperationWrapper.createWithError(ChainRegistryError.runtimeMetadaUnavailable)
        }

        let codingFactoryOperation = runtimeProvider.fetchCoderFactoryOperation()

        let operationManager = OperationManager(operationQueue: operationQueue)

        let codingFactoryClosure = { try codingFactoryOperation.extractNoCancellableResultData() }

        let accountKeysWrapper = operationFactory.createAccountKeysWrapper(
            for: ownerId,
            connection: connection,
            operationManager: operationManager,
            codingFactoryClosure: codingFactoryClosure
        )

        accountKeysWrapper.addDependency(operations: [codingFactoryOperation])

        let classIdsClosure: () throws -> [UInt32] = {
            let accountKeys = try accountKeysWrapper.targetOperation.extractNoCancellableResultData()
            return accountKeys.map(\.classId)
        }

        let instanceWrapper = operationFactory.createInstanceMetadataWrapper(
            for: classIdsClosure,
            instanceIdsClosure: {
                let accountKeys = try accountKeysWrapper.targetOperation.extractNoCancellableResultData()
                return accountKeys.map(\.instanceId)
            }, connection: connection,
            operationManager: operationManager,
            codingFactoryClosure: codingFactoryClosure
        )

        instanceWrapper.addDependency(wrapper: accountKeysWrapper)

        let remoteMapOperation = createRemoteMapOperation(
            dependingOn: accountKeysWrapper,
            instanceWrapper: instanceWrapper,
            chainId: chainId,
            ownerId: ownerId
        )

        remoteMapOperation.addDependency(accountKeysWrapper.targetOperation)
        remoteMapOperation.addDependency(instanceWrapper.targetOperation)

        let dependencies = [codingFactoryOperation] + accountKeysWrapper.allOperations +
            instanceWrapper.allOperations

        return CompoundOperationWrapper(targetOperation: remoteMapOperation, dependencies: dependencies)
    }
}
