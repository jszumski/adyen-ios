//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Adyen3DS2
import Adyen3DS2_Swift
import Foundation

internal protocol AnyAuthenticationRequestParameters {

    var deviceInformation: String { get }

    var sdkApplicationIdentifier: String { get }

    var sdkTransactionIdentifier: String { get }

    var sdkReferenceNumber: String { get }

    var sdkEphemeralPublicKey: String { get }

    // TODO: Robert: what is the purpose of having the message version here?
    // var messageVersion: String { get }
}
