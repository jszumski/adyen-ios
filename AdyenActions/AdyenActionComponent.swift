//
// Copyright (c) 2022 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Adyen
import Foundation
import UIKit

/**
  An action handler component to perform any supported action out of the box.

 - SeeAlso:
 [Implementation Reference](https://github.com/Adyen/adyen-ios#handling-an-action)
 */
public final class AdyenActionComponent: ActionComponent {
    
    public let apiContext: APIContext

    /// The Adyen context.
    public let adyenContext: AdyenContext
    
    public weak var delegate: ActionComponentDelegate?
    
    public weak var presentationDelegate: PresentationDelegate?
    
    /// Action handling configurations.
    public var configuration: Configuration
    
    /// Action handling configurations.
    public struct Configuration: Localizable {
        
        /// Localization parameters.
        public var localizationParameters: LocalizationParameters?
        
        /// The UI style configurations.
        public var style: ActionComponentStyle = .init()
        
        /// Three DS configurations
        public var threeDS: ThreeDS = .init()
        
        /// Three DS configurations
        public struct ThreeDS {
            /// `threeDSRequestorAppURL` for protocol version 2.2.0 OOB challenges
            public var requestorAppURL: URL?
            
            /// Initializes a new instance
            ///
            /// - Parameter requestorAppURL: `threeDSRequestorAppURL` for protocol version 2.2.0 OOB challenges
            public init(requestorAppURL: URL? = nil) {
                self.requestorAppURL = requestorAppURL
            }
        }
        
        /// Initializes a new instance
        ///
        /// - Parameters:
        ///   - localizationParameters: Localization parameters.
        ///   - style: The UI style configurations.
        ///   - threeDS: Three DS configurations
        public init(localizationParameters: LocalizationParameters? = nil,
                    style: ActionComponentStyle = .init(),
                    threeDS: AdyenActionComponent.Configuration.ThreeDS = .init()) {
            self.localizationParameters = localizationParameters
            self.style = style
            self.threeDS = threeDS
        }
    }

    /// :nodoc:
    internal var currentActionComponent: Component?
    
    /// :nodoc:
    public init(apiContext: APIContext,
                adyenContext: AdyenContext,
                configuration: Configuration = Configuration()) {
        self.apiContext = apiContext
        self.adyenContext = adyenContext
        self.configuration = configuration
    }
    
    // MARK: - Performing Actions
    
    /// Handles an action to complete a payment.
    ///
    /// - Parameter action: The action to handle.
    public func handle(_ action: Action) {
        switch action {
        case let .redirect(redirectAction):
            handle(redirectAction)
        case let .threeDS2Fingerprint(fingerprintAction):
            handle(fingerprintAction)
        case let .threeDS2Challenge(challengeAction):
            handle(challengeAction)
        case let .threeDS2(threeDS2Action):
            handle(threeDS2Action)
        case let .sdk(sdkAction):
            handle(sdkAction)
        case let .await(awaitAction):
            handle(awaitAction)
        case let .voucher(voucher):
            handle(voucher)
        case let .qrCode(qrCode):
            handle(qrCode)
        case let .document(documentAction):
            handle(documentAction)
        }
    }
    
    // MARK: - Private
    
    private func handle(_ action: RedirectAction) {
        let component = RedirectComponent(apiContext: apiContext)
        component.configuration.style = configuration.style.redirectComponentStyle
        component.delegate = delegate
        component._isDropIn = _isDropIn
        component.presentationDelegate = presentationDelegate
        currentActionComponent = component
        
        component.handle(action)
    }

    private func handle(_ action: ThreeDS2Action) {
        let component = createThreeDS2Component()
        currentActionComponent = component

        component.handle(action)
    }
    
    private func handle(_ action: ThreeDS2FingerprintAction) {
        let component = createThreeDS2Component()
        currentActionComponent = component
        
        component.handle(action)
    }

    private func createThreeDS2Component() -> ThreeDS2Component {
        let component = ThreeDS2Component(apiContext: apiContext,
                                          adyenContext: adyenContext)
        component.configuration.requestorAppURL = configuration.threeDS.requestorAppURL
        component._isDropIn = _isDropIn
        component.delegate = delegate
        component.presentationDelegate = presentationDelegate

        return component
    }
    
    private func handle(_ action: ThreeDS2ChallengeAction) {
        guard let threeDS2Component = currentActionComponent as? ThreeDS2Component else {
            AdyenAssertion.assertionFailure(
                // swiftlint:disable:next line_length
                message: "ThreeDS2Component is nil. There must be a ThreeDS2FingerprintAction action preceding a ThreeDS2ChallengeAction action"
            )
            return
        }
        threeDS2Component.handle(action)
    }

    private func handle(_ sdkAction: SDKAction) {
        switch sdkAction {
        case let .weChatPay(weChatPaySDKAction):
            handle(weChatPaySDKAction)
        }
    }
    
    private func handle(_ action: WeChatPaySDKAction) {
        guard let classObject = loadTheConcreteWeChatPaySDKActionComponentClass() else {
            delegate?.didFail(with: ComponentError.paymentMethodNotSupported, from: self)
            return
        }
        
        let weChatPaySDKActionComponent = classObject.init(apiContext: apiContext)
        weChatPaySDKActionComponent._isDropIn = _isDropIn
        weChatPaySDKActionComponent.delegate = delegate
        weChatPaySDKActionComponent.handle(action)
        
        currentActionComponent = weChatPaySDKActionComponent
    }
    
    private func handle(_ action: AwaitAction) {
        let component = AwaitComponent(apiContext: apiContext)
        component.configuration.style = configuration.style.awaitComponentStyle
        component._isDropIn = _isDropIn
        component.delegate = delegate
        component.presentationDelegate = presentationDelegate
        component.configuration.localizationParameters = configuration.localizationParameters
        
        component.handle(action)
        currentActionComponent = component
    }
    
    private func handle(_ action: VoucherAction) {
        let component = VoucherComponent(apiContext: apiContext)
        component.configuration.style = configuration.style.voucherComponentStyle
        component._isDropIn = _isDropIn
        component.delegate = delegate
        component.presentationDelegate = presentationDelegate
        component.configuration.localizationParameters = configuration.localizationParameters

        component.handle(action)
        currentActionComponent = component
    }
    
    private func handle(_ action: QRCodeAction) {
        let component = QRCodeComponent(apiContext: apiContext)
        component.configuration.style = configuration.style.qrCodeComponentStyle
        component._isDropIn = _isDropIn
        component.delegate = delegate
        component.presentationDelegate = presentationDelegate
        component.configuration.localizationParameters = configuration.localizationParameters
        
        component.handle(action)
        currentActionComponent = component
    }
    
    private func handle(_ action: DocumentAction) {
        let component = DocumentComponent(apiContext: apiContext)
        component.configuration.style = configuration.style.documentActionComponentStyle
        component._isDropIn = _isDropIn
        component.delegate = delegate
        component.configuration.localizationParameters = configuration.localizationParameters
        component.presentationDelegate = presentationDelegate
        
        component.handle(action)
        currentActionComponent = component
    }
}
