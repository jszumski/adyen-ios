//
//  StoredCardComponentTests.swift
//  AdyenTests
//
//  Created by Mohamed Eldoheiri on 8/17/20.
//  Copyright © 2020 Adyen. All rights reserved.
//

@testable import Adyen
@testable import AdyenCard
import XCTest

class StoredCardComponentTests: XCTestCase {

    private var analyticsProviderMock: AnalyticsProviderMock!
    private var adyenContext: AdyenContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        analyticsProviderMock = AnalyticsProviderMock()
        adyenContext = AdyenContext(analyticsProvider: analyticsProviderMock)
    }

    override func tearDownWithError() throws {
        analyticsProviderMock = nil
        adyenContext = nil
        try super.tearDownWithError()
    }

    func testUIWithClientKey() {
        let paymentMethod = storedCardPaymentMethod(brand: "brand")
        let sut = StoredCardComponent(storedCardPaymentMethod: paymentMethod,
                                      adyenContext: adyenContext)

        let payment = Payment(amount: Amount(value: 174, currencyCode: "EUR"), countryCode: "NL")
        sut.payment = payment

        UIApplication.shared.keyWindow?.rootViewController?.present(sut.viewController, animated: false, completion: nil)

        wait(for: .seconds(1))
        
        let alertController = sut.viewController as! UIAlertController
        let textField: UITextField! = alertController.textFields!.first
        XCTAssertNotNil(textField)

        XCTAssertTrue(alertController.actions.contains { $0.title == localizedString(.cancelButton, nil) })
        XCTAssertTrue(alertController.actions.contains { $0.title == localizedSubmitButtonTitle(with: payment.amount, style: .immediate, nil) })

        alertController.dismiss(animated: false, completion: nil)
    }

    func testUIWithPublicKey() {
        let paymentMethod = storedCardPaymentMethod(brand: "brand")
        let sut = StoredCardComponent(storedCardPaymentMethod: paymentMethod,
                                      adyenContext: adyenContext)
        PublicKeyProvider.publicKeysCache[Dummy.context.clientKey] = Dummy.publicKey

        let payment = Payment(amount: Amount(value: 174, currencyCode: "EUR"), countryCode: "NL")
        sut.payment = payment

        UIApplication.shared.keyWindow?.rootViewController?.present(sut.viewController, animated: false, completion: nil)

        wait(for: .seconds(1))
        let alertController = sut.viewController as! UIAlertController
        let textField: UITextField! = alertController.textFields!.first
        XCTAssertNotNil(textField)

        XCTAssertTrue(alertController.actions.contains { $0.title == localizedString(.cancelButton, nil) })
        XCTAssertTrue(alertController.actions.contains { $0.title == localizedSubmitButtonTitle(with: payment.amount, style: .immediate, nil) })

        alertController.dismiss(animated: false, completion: nil)
    }

    func testPaymentSubmitWithSuccessfulCardPublicKeyFetching() {
        let paymentMethod = storedCardPaymentMethod(brand: "brand")
        let sut = StoredCardComponent(storedCardPaymentMethod: paymentMethod,
                                      adyenContext: adyenContext)

        let payment = Payment(amount: Amount(value: 174, currencyCode: "EUR"), countryCode: "NL")
        sut.payment = payment

        let delegateExpectation = expectation(description: "expect delegate to be called.")
        let delegate = PaymentComponentDelegateMock()
        delegate.onDidSubmit = { data, component in
            XCTAssertTrue(component === sut)
            XCTAssertNotNil(data.paymentMethod as? CardDetails)

            let cardDetails = data.paymentMethod as! CardDetails
            XCTAssertNotNil(cardDetails.encryptedSecurityCode)
            XCTAssertNil(cardDetails.encryptedCardNumber)
            XCTAssertNil(cardDetails.encryptedExpiryYear)
            XCTAssertNil(cardDetails.encryptedExpiryMonth)

            delegateExpectation.fulfill()
        }
        delegate.onDidFail = { _, _ in
            XCTFail("delegate.didFail() should never be called.")
        }
        sut.delegate = delegate

        let publicKeyProviderExpectation = expectation(description: "Expect publicKeyProvider to be called.")
        let publicKeyProvider = PublicKeyProviderMock()
        publicKeyProvider.onFetch = { completion in
            publicKeyProviderExpectation.fulfill()
            completion(.success(Dummy.publicKey))
        }
        sut.storedCardAlertManager.publicKeyProvider = publicKeyProvider

        UIApplication.shared.keyWindow?.rootViewController?.present(sut.viewController, animated: false, completion: nil)

        wait(for: .seconds(1))
        
        let alertController = sut.viewController as! UIAlertController
        let textField: UITextField! = alertController.textFields!.first
        XCTAssertNotNil(textField)

        textField!.text = "737"
        textField!.sendActions(for: .editingChanged)

        let payAction = alertController.actions.first { $0.title == localizedSubmitButtonTitle(with: payment.amount, style: .immediate, nil) }!

        payAction.tap()
        
        XCTAssertTrue(textField!.text!.isEmpty)
        XCTAssertFalse(payAction.isEnabled)

        alertController.dismiss(animated: false, completion: nil)
        
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testPaymentSubmitWithFailedCardPublicKeyFetching() {
        let paymentMethod = storedCardPaymentMethod(brand: "brand")
        let sut = StoredCardComponent(storedCardPaymentMethod: paymentMethod,
                                      adyenContext: adyenContext)

        let payment = Payment(amount: Amount(value: 174, currencyCode: "EUR"), countryCode: "NL")
        sut.payment = payment

        let delegate = PaymentComponentDelegateMock()
        delegate.onDidSubmit = { _, _ in
            XCTFail("delegate.didSubmit() should never be called.")
        }
        let delegateExpectation = expectation(description: "expect delegate to be called.")
        delegate.onDidFail = { error, component in
            XCTAssertTrue(error as? Dummy == Dummy.error)
            XCTAssertTrue(component === sut)
            delegateExpectation.fulfill()
        }
        sut.delegate = delegate

        let publicKeyProviderExpectation = expectation(description: "Expect publicKeyProvider to be called.")
        let publicKeyProvider = PublicKeyProviderMock()
        publicKeyProvider.onFetch = { completion in
            publicKeyProviderExpectation.fulfill()
            completion(.failure(Dummy.error))
        }
        sut.storedCardAlertManager.publicKeyProvider = publicKeyProvider

        UIApplication.shared.keyWindow?.rootViewController?.present(sut.viewController, animated: false, completion: nil)

        wait(for: .seconds(1))
        
        let alertController = sut.viewController as! UIAlertController
        let textField: UITextField! = alertController.textFields!.first
        XCTAssertNotNil(textField)

        textField.text = "737"
        textField.sendActions(for: .editingChanged)

        let payAction = alertController.actions.first { $0.title == localizedSubmitButtonTitle(with: payment.amount, style: .immediate, nil) }!

        payAction.tap()

        alertController.dismiss(animated: false, completion: nil)
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testCVCLimitForAMEX() {
        let paymentMethod = storedCardPaymentMethod(brand: "amex")
        let sut = StoredCardComponent(storedCardPaymentMethod: paymentMethod,
                                      adyenContext: adyenContext)

        let payment = Payment(amount: Amount(value: 174, currencyCode: "EUR"), countryCode: "NL")
        sut.payment = payment

        UIApplication.shared.keyWindow?.rootViewController?.present(sut.viewController, animated: false, completion: nil)

        wait(for: .seconds(1))
        
        let alertController = sut.viewController as! UIAlertController
        let textField: UITextField! = alertController.textFields!.first
        let payAction = alertController.actions.first { $0.title == localizedSubmitButtonTitle(with: payment.amount, style: .immediate, nil) }!

        textField.insertText("a")
        textField?.sendActions(for: .editingChanged)
        XCTAssertEqual(textField.delegate!.textField!(textField, shouldChangeCharactersIn: NSRange(location: 0, length: 1), replacementString: "a"), false)

        textField.text = "1"
        textField?.sendActions(for: .editingChanged)
        XCTAssertEqual(textField.delegate!.textField!(textField, shouldChangeCharactersIn: NSRange(location: 0, length: 1), replacementString: "1"), true)

        textField.text = "11"
        textField?.sendActions(for: .editingChanged)
        XCTAssertEqual(textField.delegate!.textField!(textField, shouldChangeCharactersIn: NSRange(location: 1, length: 1), replacementString: "1"), true)

        textField.text = "111"
        textField?.sendActions(for: .editingChanged)
        XCTAssertEqual(textField.delegate!.textField!(textField, shouldChangeCharactersIn: NSRange(location: 2, length: 1), replacementString: "1"), true)
        XCTAssertEqual(payAction.isEnabled, false)

        textField.text = "1111"
        textField?.sendActions(for: .editingChanged)
        XCTAssertEqual(textField.delegate!.textField!(textField, shouldChangeCharactersIn: NSRange(location: 3, length: 1), replacementString: "1"), true)
        XCTAssertEqual(payAction.isEnabled, true)

        textField.text = "11111"
        textField?.sendActions(for: .editingChanged)
        XCTAssertEqual(textField.delegate!.textField!(textField, shouldChangeCharactersIn: NSRange(location: 4, length: 1), replacementString: "1"), false)

        alertController.dismiss(animated: false, completion: nil)
    }

    func testCVCLimitForNonAMEX() {
        let paymentMethod = storedCardPaymentMethod(brand: "mc")
        let sut = StoredCardComponent(storedCardPaymentMethod: paymentMethod,
                                      adyenContext: adyenContext)

        let payment = Payment(amount: Amount(value: 174, currencyCode: "EUR"), countryCode: "NL")
        sut.payment = payment

        UIApplication.shared.keyWindow?.rootViewController?.present(sut.viewController, animated: false, completion: nil)

        wait(for: .seconds(1))
        
        let alertController = sut.viewController as! UIAlertController
        let textField: UITextField! = alertController.textFields!.first
        let payAction = alertController.actions.first { $0.title == localizedSubmitButtonTitle(with: payment.amount, style: .immediate, nil) }!

        textField.text = "11"
        textField?.sendActions(for: .editingChanged)
        XCTAssertEqual(textField.delegate!.textField!(textField, shouldChangeCharactersIn: NSRange(location: 1, length: 1), replacementString: "1"), true)
        XCTAssertEqual(payAction.isEnabled, false)

        textField.text = "111"
        textField?.sendActions(for: .editingChanged)
        XCTAssertEqual(textField.delegate!.textField!(textField, shouldChangeCharactersIn: NSRange(location: 2, length: 1), replacementString: "1"), true)
        XCTAssertEqual(payAction.isEnabled, true)

        textField.text = "1111"
        textField?.sendActions(for: .editingChanged)
        XCTAssertEqual(textField.delegate!.textField!(textField, shouldChangeCharactersIn: NSRange(location: 3, length: 1), replacementString: "1"), true)
        XCTAssertEqual(payAction.isEnabled, true)

        textField.text = "11111"
        textField?.sendActions(for: .editingChanged)
        XCTAssertEqual(textField.delegate!.textField!(textField, shouldChangeCharactersIn: NSRange(location: 4, length: 1), replacementString: "1"), false)

        alertController.dismiss(animated: false, completion: nil)
    }

    func testCVCLimitForUnknownCardType() {
        let paymentMethod = storedCardPaymentMethod(brand: "some_brand")
        let sut = StoredCardComponent(storedCardPaymentMethod: paymentMethod,
                                      adyenContext: adyenContext)

        let payment = Payment(amount: Amount(value: 174, currencyCode: "EUR"), countryCode: "NL")
        sut.payment = payment

        UIApplication.shared.keyWindow?.rootViewController?.present(sut.viewController, animated: false, completion: nil)

        wait(for: .seconds(1))
        
        let alertController = sut.viewController as! UIAlertController
        let textField: UITextField! = alertController.textFields!.first
        let payAction = alertController.actions.first { $0.title == localizedSubmitButtonTitle(with: payment.amount, style: .immediate, nil) }!

        textField.text = "11"
        textField?.sendActions(for: .editingChanged)
        XCTAssertEqual(textField.delegate!.textField!(textField, shouldChangeCharactersIn: NSRange(location: 1, length: 1), replacementString: "1"), true)
        XCTAssertEqual(payAction.isEnabled, false)

        textField.text = "111"
        textField?.sendActions(for: .editingChanged)
        XCTAssertEqual(textField.delegate!.textField!(textField, shouldChangeCharactersIn: NSRange(location: 2, length: 1), replacementString: "1"), true)
        XCTAssertEqual(payAction.isEnabled, true)

        textField.text = "1111"
        textField?.sendActions(for: .editingChanged)
        XCTAssertEqual(textField.delegate!.textField!(textField, shouldChangeCharactersIn: NSRange(location: 3, length: 1), replacementString: "1"), true)

        alertController.dismiss(animated: false, completion: nil)
    }

    func testViewDidLoadShouldSendTelemetryEvent() throws {
        // Given
        let paymentMethod = storedCardPaymentMethod(brand: "some_brand")
        let sut = StoredCardComponent(storedCardPaymentMethod: paymentMethod,
                                      adyenContext: adyenContext)

        // When
        sut.viewController.viewDidLoad()

        // Then
        XCTAssertEqual(analyticsProviderMock.trackTelemetryEventCallsCount, 1)
    }

    // MARK: - Private

    private func storedCardPaymentMethod(brand: String) -> StoredCardPaymentMethod {
        .init(type: .card,
              name: "name",
              identifier: "id",
              fundingSource: .credit,
              supportedShopperInteractions: [.shopperPresent],
              brand: brand,
              lastFour: "1234",
              expiryMonth: "12",
              expiryYear: "22",
              holderName: "holderName")
    }
}

extension UIAlertAction {
    typealias AlertHandler = @convention(block) (UIAlertAction) -> Void

    func tap() {
        let closure = self.value(forKey: "handler")

        let handler = unsafeBitCast(closure as AnyObject, to: AlertHandler.self)

        handler(self)
    }
}
