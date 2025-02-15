import Combine
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

class CoinAuditsViewModel {
    private let service: CoinAuditsService
    private var cancellables = Set<AnyCancellable>()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: CoinAuditsService) {
        self.service = service

        service.$state
            .sink { [weak self] in self?.sync(state: $0) }
            .store(in: &cancellables)

        sync(state: service.state)
    }

    private func sync(state: DataStatus<[CoinAuditsService.Item]>) {
        switch state {
        case .loading:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(true)
            syncErrorRelay.accept(false)
        case let .completed(items):
            viewItemsRelay.accept(items.map { viewItem(item: $0) })
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)
        case .failed:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
        }
    }

    private func auditViewItem(report: AuditReport) -> AuditViewItem {
        AuditViewItem(
            date: DateHelper.instance.formatFullDateOnly(from: report.date),
            name: report.name,
            issues: "coin_analytics.audits.issues".localized + ": \(report.issues)",
            reportUrl: report.link
        )
    }

    private func viewItem(item: CoinAuditsService.Item) -> ViewItem {
        ViewItem(
            logoUrl: item.logoUrl,
            name: item.name,
            auditViewItems: item.reports.map { auditViewItem(report: $0) }
        )
    }
}

extension CoinAuditsViewModel {
    var viewItemsDriver: Driver<[ViewItem]?> {
        viewItemsRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    func onTapRetry() {
        service.refresh()
    }
}

extension CoinAuditsViewModel {
    struct ViewItem {
        let logoUrl: String?
        let name: String
        let auditViewItems: [AuditViewItem]
    }

    struct AuditViewItem {
        let date: String?
        let name: String
        let issues: String
        let reportUrl: String?
    }
}
