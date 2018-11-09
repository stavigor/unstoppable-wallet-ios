import UIKit

class TransactionsRouter {
    weak var viewController: UIViewController?
    var view: Any?
}

extension TransactionsRouter: ITransactionsRouter {

    func openTransactionInfo(transactionHash: String) {
//        view = TransactionInfoRouter.module(controller: viewController, transaction: transaction)
    }

}

extension TransactionsRouter {

    static func module() -> UIViewController {
        let dataSource = TransactionRecordDataSource(realmFactory: App.shared.realmFactory)

        let router = TransactionsRouter()
        let interactor = TransactionsInteractor(walletManager: App.shared.walletManager, exchangeRateManager: App.shared.rateManager, dataSource: dataSource)
        let presenter = TransactionsPresenter(interactor: interactor, router: router, factory: App.shared.transactionViewItemFactory)
        let viewController = TransactionsViewController(delegate: presenter)

        dataSource.delegate = interactor
        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
