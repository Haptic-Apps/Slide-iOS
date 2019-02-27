//
//  IAPHandlerTip.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 2/23/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import StoreKit
import UIKit

class IAPHandlerTip: NSObject {
    static let shared = IAPHandlerTip()
    
    let TIPA = "3tip"
    let TIPB = "5tip"
    let TIPC = "10tip"
    
    private var productID = ""
    private var productsRequest = SKProductsRequest()
    public var iapProducts = [SKProduct]()
    
    var purchaseStatusBlock: ((IAPHandlerAlertType) -> Void)?
    var restoreBlock: ((Bool) -> Void)?
    var errorBlock: ((String?) -> Void)?
    
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
        } else {
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
        let productIdentifiers = NSSet(objects: TIPA, TIPB, TIPC)
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers as! Set<String>)
        productsRequest.delegate = self
        productsRequest.start()
    }
}

extension IAPHandlerTip: SKProductsRequestDelegate, SKPaymentTransactionObserver {
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
        var failed: String?
        var didFail = false
        for transaction: AnyObject in transactions {
            if let trans = transaction as? SKPaymentTransaction {
                switch trans.transactionState {
                case .purchased:
                    print("Product Purchased")
                    purchaseStatusBlock?(.purchased)
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                case .failed:
                    print("Purchased Failed")
                    didFail = true
                    failed = trans.error?.localizedDescription
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                case .restored:
                    print("Already Purchased")
                    purchaseStatusBlock?(.purchased)
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                default:
                    break
                }
            }
        }
        
        if didFail {
            errorBlock?(failed)
        }
    }
}
