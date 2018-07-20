//
//  IAPHandler.swift
//
//  Created by Dejan Atanasov on 13/07/2017.
//  Copyright © 2017 Dejan Atanasov. All rights reserved.
//
import StoreKit
import UIKit

enum IAPHandlerAlertType {
    case disabled
    case restored
    case purchased
    
    func message() -> String {
        switch self {
        case .disabled: return "Purchases are disabled on your device!"
        case .restored: return "You've successfully restored your purchase, thank you for supporting Slide!"
        case .purchased: return "Thank you for going Pro and supporting Slide for Reddit!\n\nAll pro features will now be enabled."
        }
    }
}

class IAPHandler: NSObject {
    static let shared = IAPHandler()
    
    let PRO = "me.ccrama.pro.base"
    let PRO_DONATE = "me.ccrama.pro.donate"

    fileprivate var productID = ""
    fileprivate var productsRequest = SKProductsRequest()
    public var iapProducts = [SKProduct]()
    
    var purchaseStatusBlock: ((IAPHandlerAlertType) -> Void)?
    var getItemsBlock: (([SKProduct]) -> Void)?

    // MARK: - MAKE PURCHASE OF A PRODUCT
    func canMakePurchases() -> Bool { return SKPaymentQueue.canMakePayments() }
    
    func purchaseMyProduct(index: Int) {
        print("Purchasing")
        if iapProducts.count == 0 { return }
        
        if self.canMakePurchases() {
            let product = iapProducts[index]
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)
            
            print("PRODUCT TO PURCHASE: \(product.productIdentifier)")
            productID = product.productIdentifier
        }
        else {
            purchaseStatusBlock?(.disabled)
        }
    }
    
    // MARK: - RESTORE PURCHASE
    func restorePurchase() {
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK: - FETCH AVAILABLE IAP PRODUCTS
    func fetchAvailableProducts() {
        
        // Put here your IAP Products ID's
        let productIdentifiers = NSSet(objects: PRO, PRO_DONATE)
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers as! Set<String>)
        productsRequest.delegate = self
        productsRequest.start()
    }
}

extension IAPHandler: SKProductsRequestDelegate, SKPaymentTransactionObserver {
    // MARK: - REQUEST IAP PRODUCTS
    func productsRequest (_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        getItemsBlock?(response.products)
        if response.products.count > 0 {
            iapProducts = response.products
            for product in iapProducts {
                let numberFormatter = NumberFormatter()
                numberFormatter.formatterBehavior = .behavior10_4
                numberFormatter.numberStyle = .currency
                numberFormatter.locale = product.priceLocale
                let price1Str = numberFormatter.string(from: product.price)
                print(product.localizedDescription + "\nfor just \(price1Str!)")
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        purchaseStatusBlock?(.restored)
    }
    
    // MARK: - IAP PAYMENT QUEUE
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction: AnyObject in transactions {
            if let trans = transaction as? SKPaymentTransaction {
                switch trans.transactionState {
                case .purchased:
                    print("purchased")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    purchaseStatusBlock?(.purchased)
                    
                case .failed:
                    print("failed")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)

                case .restored:
                    print("restored")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    
                default:
                    break
                }}}
    }
}
