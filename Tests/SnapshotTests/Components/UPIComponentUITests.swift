//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@_spi(AdyenInternal) @testable import Adyen
@testable import AdyenComponents
import AdyenDropIn
import XCTest

class UPIComponentUITests: XCTestCase {

    private var paymentMethod: UPIPaymentMethod!
    private var context: AdyenContext!
    private var style: FormComponentStyle!
    private var upiApps: [Issuer]!

    override func setUpWithError() throws {
        try super.setUpWithError()
        upiApps = [
            Issuer(identifier: "bhim", name: "BHIM"),
            Issuer(identifier: "gpay", name: "Google Pay"),
            Issuer(identifier: "phonepe", name: "PhonePe")
        ]
        paymentMethod = UPIPaymentMethod(type: .upi,
                                         name: "upi",
                                         apps: upiApps)
        context = Dummy.context
        style = FormComponentStyle()
        BrowserInfo.cachedUserAgent = "some_value"
    }

    override func tearDownWithError() throws {
        paymentMethod = nil
        context = nil
        style = nil
        try super.tearDownWithError()
    }

    func testUIConfiguration() throws {
        style.backgroundColor = .green
        
        /// Footer
        style.mainButtonItem.button.title.color = .white
        style.mainButtonItem.button.title.backgroundColor = .red
        style.mainButtonItem.button.title.textAlignment = .center
        style.mainButtonItem.button.title.font = .systemFont(ofSize: 22)
        style.mainButtonItem.button.backgroundColor = .red
        style.mainButtonItem.backgroundColor = .brown
        
        /// Text field
        style.textField.text.color = .yellow
        style.textField.text.font = .systemFont(ofSize: 5)
        style.textField.text.textAlignment = .center
        style.textField.placeholderText = TextStyle(font: .preferredFont(forTextStyle: .headline),
                                                    color: .systemOrange,
                                                    textAlignment: .center)
        
        style.textField.title.backgroundColor = .blue
        style.textField.title.color = .green
        style.textField.title.font = .systemFont(ofSize: 18)
        style.textField.title.textAlignment = .left
        style.textField.backgroundColor = .blue
    
        let config = UPIComponent.Configuration(style: style)
        let sut = UPIComponent(paymentMethod: paymentMethod,
                               context: context,
                               configuration: config)
    
        assertViewControllerImage(matching: sut.viewController, named: "UI_configuration")
    }
    
    func testUIConfigurationForIndexOne() throws {
    
        style.backgroundColor = .green
        
        /// Footer
        style.mainButtonItem.button.title.color = .white
        style.mainButtonItem.button.title.backgroundColor = .red
        style.mainButtonItem.button.title.textAlignment = .center
        style.mainButtonItem.button.title.font = .systemFont(ofSize: 22)
        style.mainButtonItem.button.backgroundColor = .red
        style.mainButtonItem.backgroundColor = .brown
        
        /// Text field
        style.textField.text.color = .yellow
        style.textField.text.font = .systemFont(ofSize: 5)
        style.textField.text.textAlignment = .center
        style.textField.placeholderText = TextStyle(font: .preferredFont(forTextStyle: .headline),
                                                    color: .systemOrange,
                                                    textAlignment: .center)
        
        style.textField.title.backgroundColor = .blue
        style.textField.title.color = .green
        style.textField.title.font = .systemFont(ofSize: 18)
        style.textField.title.textAlignment = .left
        style.textField.backgroundColor = .blue
        
        /// segmentedControlStyle
        style.segmentedControlStyle.tintColor = .yellow
        style.segmentedControlStyle.backgroundColor = .blue
        style.segmentedControlStyle.textStyle.backgroundColor = .systemPink
        style.segmentedControlStyle.textStyle.font = .systemFont(ofSize: 10)
        style.segmentedControlStyle.textStyle.textAlignment = .center
        style.segmentedControlStyle.textStyle.color = .red
    
        let config = UPIComponent.Configuration(style: style)
        let sut = UPIComponent(paymentMethod: paymentMethod,
                               context: context,
                               configuration: config)
        sut.currentSelectedIndex = 1

        assertViewControllerImage(matching: sut.viewController, named: "UI_configuration_Index_One")
    }

    func testUIElementsForPayByAnyUPIAppFlowType() {
        // Assert
        let config = UPIComponent.Configuration(style: style)
        let sut = UPIComponent(paymentMethod: paymentMethod,
                               context: context,
                               configuration: config)
        assertViewControllerImage(matching: sut.viewController, named: "all_required_fields_exist")
    }

    func testUPIComponentDetailsForUPIIntentFlow() {
        // Given
        let config = UPIComponent.Configuration(style: style)
        let sut = UPIComponent(paymentMethod: paymentMethod,
                               context: context,
                               configuration: config)
        sut.currentSelectedIndex = 0

        let didSubmitExpectation = expectation(description: "PaymentComponentDelegate must be called when submit button is clicked.")

        let delegateMock = PaymentComponentDelegateMock()
        sut.delegate = delegateMock

        delegateMock.onDidSubmit = { data, component in
            // Assert
            XCTAssertTrue(component === sut)
            XCTAssertTrue(data.paymentMethod is UPIComponentDetails)
            let data = data.paymentMethod as! UPIComponentDetails
            XCTAssertEqual(data.virtualPaymentAddress, nil)
            XCTAssertEqual(data.type, "upi_intent")
            didSubmitExpectation.fulfill()
        }

        wait(for: .milliseconds(300))
        
        sut.currentSelectedItem = sut.upiAppsList.first
        sut.virtualPaymentAddressItem.isVisible = false

        assertViewControllerImage(matching: sut.viewController, named: "upi_intent")

        let continueButton: UIControl? = sut.viewController.view.findView(with: "AdyenComponents.UPIComponent.continueButton.button")
        continueButton?.sendActions(for: .touchUpInside)
    
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testUPIComponentDetailsForUPICollectFlow() {
        // Given
        let config = UPIComponent.Configuration(style: style)
        let sut = UPIComponent(paymentMethod: paymentMethod,
                               context: context,
                               configuration: config)
        sut.currentSelectedIndex = 0

        let didSubmitExpectation = expectation(description: "PaymentComponentDelegate must be called when submit button is clicked.")

        let delegateMock = PaymentComponentDelegateMock()
        sut.delegate = delegateMock

        delegateMock.onDidSubmit = { data, component in
            // Assert
            XCTAssertTrue(component === sut)
            XCTAssertTrue(data.paymentMethod is UPIComponentDetails)
            let data = data.paymentMethod as! UPIComponentDetails
            XCTAssertEqual(data.virtualPaymentAddress, "testvpa@icici")
            XCTAssertEqual(data.type, "upi_collect")
            didSubmitExpectation.fulfill()
        }

        wait(for: .milliseconds(300))

        sut.currentSelectedItem = sut.upiAppsList.last
        sut.virtualPaymentAddressItem.isVisible = true
        sut.virtualPaymentAddressItem.value = "testvpa@icici"
        
        assertViewControllerImage(matching: sut.viewController, named: "prefilled_vpa")

        let continueButton: UIControl? = sut.viewController.view.findView(with: "AdyenComponents.UPIComponent.continueButton.button")
        continueButton?.sendActions(for: .touchUpInside)

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testUPIComponentDetailsForUPIQRCodeFlow() {
        // Given
        let config = UPIComponent.Configuration(style: style)
        let sut = UPIComponent(paymentMethod: paymentMethod,
                               context: context,
                               configuration: config)

        sut.didChangeSegmentedControlIndex(1)

        let continueButton: UIControl? = sut.viewController.view.findView(with: "AdyenComponents.UPIComponent.generateQRCodeButton.button")
        
        let dummyExpectation = XCTestExpectation(description: "Dummy Expectation")
        
        let delegateMock = PaymentComponentDelegateMock()
        sut.delegate = delegateMock
        
        delegateMock.onDidSubmit = { data, component in
            // Assert
            XCTAssertTrue(component === sut)
            XCTAssertTrue(data.paymentMethod is UPIComponentDetails)
            let data = data.paymentMethod as! UPIComponentDetails
            XCTAssertNotNil(data.type)
            XCTAssertEqual(data.type, "upi_qr")
            sut.stopLoadingIfNeeded()
            
            self.wait(for: .aMoment)
            self.assertViewControllerImage(matching: sut.viewController, named: "upi_qr_flow")
            dummyExpectation.fulfill()
        }
        
        continueButton?.sendActions(for: .touchUpInside)
        
        wait(for: [dummyExpectation], timeout: 5)
    }

}
