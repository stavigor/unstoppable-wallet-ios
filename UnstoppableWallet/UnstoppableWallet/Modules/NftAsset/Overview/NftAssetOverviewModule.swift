import UIKit

enum NftAssetOverviewModule {
    static func viewController(providerCollectionUid: String, nftUid: NftUid) -> NftAssetOverviewViewController {
        let coinPriceService = WalletCoinPriceService(
            tag: "nft-asset-overview",
            currencyManager: App.shared.currencyManager,
            marketKit: App.shared.marketKit
        )

        let service = NftAssetOverviewService(
            providerCollectionUid: providerCollectionUid,
            nftUid: nftUid,
            accountManager: App.shared.accountManager,
            nftAdapterManager: App.shared.nftAdapterManager,
            nftMetadataManager: App.shared.nftMetadataManager,
            marketKit: App.shared.marketKit,
            coinPriceService: coinPriceService
        )

        coinPriceService.delegate = service

        let viewModel = NftAssetOverviewViewModel(service: service)
        return NftAssetOverviewViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }
}

enum NftImage {
    case image(image: UIImage)
    case svg(string: String)

    var ratio: CGFloat {
        switch self {
        case let .image(image): return image.size.height / image.size.width
        case .svg: return 1
        }
    }
}
