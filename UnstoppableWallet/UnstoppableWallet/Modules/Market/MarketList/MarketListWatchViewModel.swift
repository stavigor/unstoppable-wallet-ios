import MarketKit
import RxCocoa
import RxRelay
import RxSwift

protocol IMarketListWatchViewModel: IMarketListViewModel {
    var favoriteDriver: Driver<Void> { get }
    var unfavoriteDriver: Driver<Void> { get }
    var failDriver: Driver<String> { get }

    func isFavorite(index: Int) -> Bool?
    func favorite(index: Int)
    func unfavorite(index: Int)
}

class MarketListWatchViewModel<Service: IMarketListService, Decorator: IMarketListDecorator>: MarketListViewModel<Service, Decorator> {
    private let disposeBag = DisposeBag()

    private let watchlistToggleService: MarketWatchlistToggleService

    private let favoriteRelay = PublishRelay<Void>()
    private let unfavoriteRelay = PublishRelay<Void>()
    private let failRelay = PublishRelay<String>()

    init(service: Service, watchlistToggleService: MarketWatchlistToggleService, decorator: Decorator) {
        self.watchlistToggleService = watchlistToggleService

        super.init(service: service, decorator: decorator)

        subscribe(disposeBag, watchlistToggleService.statusObservable) { [weak self] in self?.handle(status: $0) }
    }

    private func handle(status: MarketWatchlistToggleService.State) {
        switch status {
        case .favorite:
            favoriteRelay.accept(())
        case .unfavorite:
            unfavoriteRelay.accept(())
        case .fail:
            failRelay.accept("watch_coin.fail_to_find_uuid")
        }
    }
}

extension MarketListWatchViewModel: IMarketListWatchViewModel {
    var favoriteDriver: Driver<Void> {
        favoriteRelay.asDriver(onErrorJustReturn: ())
    }

    var unfavoriteDriver: Driver<Void> {
        unfavoriteRelay.asDriver(onErrorJustReturn: ())
    }

    var failDriver: Driver<String> {
        failRelay.asDriver(onErrorJustReturn: "")
    }

    func isFavorite(index: Int) -> Bool? {
        watchlistToggleService.isFavorite(index: index)
    }

    func favorite(index: Int) {
        watchlistToggleService.favorite(index: index)
    }

    func unfavorite(index: Int) {
        watchlistToggleService.unfavorite(index: index)
    }
}
