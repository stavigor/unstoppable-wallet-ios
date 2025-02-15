import Combine
import RxCocoa
import RxRelay
import RxSwift

class MarketOverviewViewModel {
    private let service: MarketOverviewService
    private var cancellables = Set<AnyCancellable>()

    private let successRelay = BehaviorRelay<Bool>(value: false)
    private let loadingRelay = BehaviorRelay<Bool>(value: true)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: MarketOverviewService) {
        self.service = service

        service.$state
            .sink { [weak self] in self?.sync(state: $0) }
            .store(in: &cancellables)

        sync(state: service.state)
    }

    private func sync(state: DataStatus<MarketOverviewService.Item>) {
        switch state {
        case .loading:
            loadingRelay.accept(true)
            syncErrorRelay.accept(false)
            successRelay.accept(false)
        case .completed:
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)
            successRelay.accept(true)
        case .failed:
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
            successRelay.accept(false)
        }
    }
}

extension MarketOverviewViewModel {
    var successDriver: Driver<Bool> {
        successRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    func onLoad() {
        service.load()
    }

    func refresh() {
        service.refresh()
    }
}
