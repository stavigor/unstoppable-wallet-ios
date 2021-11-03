import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import SnapKit
import ComponentKit
import HUD
import MarketKit

class CoinDetailsViewController: ThemeViewController {
    private let viewModel: CoinDetailsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = MarketListErrorView()

    weak var parentNavigationController: UINavigationController?

    private var viewItem: CoinDetailsViewModel.ViewItem?

    init(viewModel: CoinDetailsViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self

        tableView.showsVerticalScrollIndicator = false

        tableView.registerCell(forClass: BCell.self)
        tableView.registerCell(forClass: D1Cell.self)
        tableView.registerCell(forClass: D2Cell.self)
        tableView.registerCell(forClass: D6Cell.self)
        tableView.registerCell(forClass: D7Cell.self)
        tableView.registerCell(forClass: D20Cell.self)

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        errorView.onTapRetry = { [weak self] in self?.viewModel.onTapRetry() }

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in self?.sync(viewItem: $0) }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.errorDriver) { [weak self] error in
            if let error = error {
                self?.errorView.text = error
                self?.errorView.isHidden = false
            } else {
                self?.errorView.isHidden = true
            }
        }

        viewModel.onLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    private func sync(viewItem: CoinDetailsViewModel.ViewItem?) {
        self.viewItem = viewItem

        if viewItem != nil {
            tableView.bounces = true
        } else {
            tableView.bounces = false
        }

        tableView.reload()
    }

    private func openMajorHolders(address: String) {
        let viewController = CoinMajorHoldersModule.viewController(address: address)
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func openAudits(addresses: [String]) {
        let viewController = CoinAuditsModule.viewController(addresses: addresses)
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func openSecurityInfo(type: CoinDetailsViewModel.SecurityType) {
        let viewController = CoinPageInfoViewController(header: type.title, viewItems: viewModel.securityInfoViewItems(type: type))
        parentNavigationController?.present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

    private func openTreasuries() {
    }

    private func openFundsInvested() {
        let viewController = CoinInvestorsModule.viewController(coinUid: viewModel.coinUid)
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func openTvl() {
//        let viewController = CoinTvlModule.viewController(coinType: viewModel.coinType.coinType)
//        present(viewController, animated: true)
    }

    private func openTvlRank() {
//        let viewController = CoinTvlRankModule.viewController()
//        navigationController?.pushViewController(viewController, animated: true)
    }

//    private func openTradingVolume() {
//        let viewController = CoinTradingVolumeModule.viewController(coinType: viewModel.coinType.coinType, coinTitle: viewModel.coinTitle)
//        present(viewController, animated: true)
//    }

}

extension CoinDetailsViewController: SectionsDataSource {

    private func headerRow(title: String, topSeparator: Bool = true) -> RowProtocol {
        Row<BCell>(
                id: "header_cell_\(title)",
                hash: title,
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent, isFirst: !topSeparator)
                    cell.selectionStyle = .none
                    cell.title = title
                }
        )
    }

    private func liquiditySections() -> [SectionProtocol] {
        [
            Section(
                    id: "liquidity-header",
                    footerState: .margin(height: .margin12),
                    rows: [
                        headerRow(title: "coin_page.token_liquidity".localized, topSeparator: false),
                    ]
            ),
            Section(
                    id: "liquidity",
                    footerState: .margin(height: .margin24),
                    rows: [
                    ]
            )
        ]
    }

    private func distributionSections(viewItem: CoinDetailsViewModel.ViewItem) -> [SectionProtocol]? {
        guard let address = viewItem.majorHoldersErc20Address else {
            return nil
        }

        return [
            Section(
                    id: "distribution-header",
                    footerState: .margin(height: .margin12),
                    rows: [
                        headerRow(title: "coin_page.token_distribution".localized)
                    ]
            ),
            Section(
                    id: "distribution",
                    footerState: .margin(height: .margin24),
                    rows: [
                        Row<D1Cell>(
                                id: "major-holders",
                                height: .heightCell48,
                                bind: { cell, _ in
                                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                                    cell.title = "coin_page.major_holders".localized
                                },
                                action: { [weak self] _ in
                                    self?.openMajorHolders(address: address)
                                }
                        )
                    ]
            )
        ]
    }

    private func tvlSections(viewItem: CoinDetailsViewModel.ViewItem) -> [SectionProtocol]? {
        guard let tvl = viewItem.tvl else {
            return nil
        }

        let tvlRow = Row<D6Cell>(
                id: "tvl_chart",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                    cell.title = "coin_page.tvl".localized
                    cell.value = tvl
                    cell.valueColor = .themeOz
                    cell.valueImage = UIImage(named: "chart_20")
                    cell.valueImageTintColor = .themeGray
                },
                action: { [weak self] _ in
                    self?.openTvl()
                }
        )

        var sections: [SectionProtocol] = [
            Section(
                    id: "tvl-header",
                    footerState: .margin(height: .margin12),
                    rows: [
                        headerRow(title: "coin_page.token_tvl".localized),
                    ]
            ),
            Section(
                    id: "tvl",
                    footerState: .margin(height: .margin12),
                    rows: [
                        tvlRow
                    ]
            )
        ]

        var rows = [RowProtocol]()

        let hasRank = viewItem.tvlRank != nil
        let hasRatio = viewItem.tvlRatio != nil

        if let tvlRank = viewItem.tvlRank {
            let tvlRankRow = Row<D2Cell>(
                    id: "market-cap-tvl-rank",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: !hasRatio)
                        cell.title = "coin_page.tvl_rank".localized
                        cell.value = tvlRank
                        cell.valueColor = .themeOz
                    },
                    action: { [weak self] _ in
                        self?.openTvlRank()
                    }
            )

            rows.append(tvlRankRow)
        }

        if let tvlRatio = viewItem.tvlRatio {
            let tvlRatioRow = Row<D7Cell>(
                    id: "market-cap-tvl-ratio",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: !hasRank, isLast: true)
                        cell.title = "coin_page.market_cap_tvl_ratio".localized
                        cell.value = tvlRatio
                    }
            )

            rows.append(tvlRatioRow)
        }

        sections.append(Section(
                id: "tvl-info",
                footerState: .margin(height: rows.isEmpty ? .margin12 : .margin24),
                rows: rows
        ))

        return sections
    }

    private func investorDataSections(viewItem: CoinDetailsViewModel.ViewItem) -> [SectionProtocol]? {
        let treasuries = viewItem.treasuries
        let fundsInvested = viewItem.fundsInvested

        var rows = [RowProtocol]()

        let hasTreasuries = treasuries != nil
        let hasFundsInvested = fundsInvested != nil

        if let treasuries = treasuries {
            let row = Row<D2Cell>(
                    id: "treasuries",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: !hasFundsInvested)
                        cell.title = "coin_page.treasuries".localized
                        cell.value = treasuries
                        cell.valueColor = .themeOz
                    },
                    action: { [weak self] _ in
                        self?.openTreasuries()
                    }
            )

            rows.append(row)
        }

        if let fundsInvested = fundsInvested {
            let row = Row<D2Cell>(
                    id: "funds-invested",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: !hasTreasuries, isLast: true)
                        cell.title = "coin_page.funds_invested".localized
                        cell.value = fundsInvested
                        cell.valueColor = .themeOz
                    },
                    action: { [weak self] _ in
                        self?.openFundsInvested()
                    }
            )

            rows.append(row)
        }

        if rows.isEmpty {
            return nil
        } else {
            return [
                Section(
                        id: "investor-data-header",
                        footerState: .margin(height: .margin12),
                        rows: [
                            headerRow(title: "coin_page.investor_data".localized)
                        ]
                ),
                Section(
                        id: "investor-data",
                        footerState: .margin(height: .margin24),
                        rows: rows
                )
            ]
        }
    }

    private func securitySections(viewItem: CoinDetailsViewModel.ViewItem) -> [SectionProtocol]? {
        let securityViewItems = viewItem.securityViewItems
        let auditAddresses = viewItem.auditAddresses

        var rows = [RowProtocol]()

        let hasSecurity = !securityViewItems.isEmpty
        let hasAudits = !auditAddresses.isEmpty

        for (index, viewItem) in securityViewItems.enumerated() {
            let row = Row<D20Cell>(
                    id: "security-\(viewItem.type)",
                    height: .heightCell48,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: index == 0, isLast: index == securityViewItems.count - 1 && !hasAudits)
                        cell.title = viewItem.type.title
                        cell.value = viewItem.value
                        cell.valueBackground = viewItem.valueGrade.color
                        cell.image = UIImage(named: "circle_information_20")
                    },
                    action: { [weak self] _ in
                        self?.openSecurityInfo(type: viewItem.type)
                    }
            )

            rows.append(row)
        }

        if !auditAddresses.isEmpty {
            let row = Row<D1Cell>(
                    id: "audits",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: !hasSecurity, isLast: true)
                        cell.title = "coin_page.audits".localized
                    },
                    action: { [weak self] _ in
                        self?.openAudits(addresses: auditAddresses)
                    }
            )

            rows.append(row)
        }

        if rows.isEmpty {
            return nil
        } else {
            return [
                Section(
                        id: "security-parameters-header",
                        footerState: .margin(height: .margin12),
                        rows: [
                            headerRow(title: "coin_page.security_parameters".localized)
                        ]
                ),
                Section(
                        id: "security-parameters",
                        footerState: .margin(height: .margin24),
                        rows: rows
                )
            ]
        }
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItem = viewItem {
            sections.append(contentsOf: liquiditySections())

            if let distributionSections = distributionSections(viewItem: viewItem) {
                sections.append(contentsOf: distributionSections)
            }

            if let tvlSections = tvlSections(viewItem: viewItem) {
                sections.append(contentsOf: tvlSections)
            }

            if let investorDataSections = investorDataSections(viewItem: viewItem) {
                sections.append(contentsOf: investorDataSections)
            }

            if let securitySections = securitySections(viewItem: viewItem) {
                sections.append(contentsOf: securitySections)
            }
        }

        return sections
    }

}

extension CoinDetailsViewModel.SecurityGrade {

    var color: UIColor {
        switch self {
        case .low: return .themeLucian
        case .medium: return .themeIssykBlue
        case .high: return .themeRemus
        }
    }

}
