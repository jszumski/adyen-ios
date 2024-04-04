//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import AdyenActions
@testable import AdyenCard
import Foundation

final class AnyRedirectComponentMock: AnyRedirectComponent {
    
    var context: AdyenContext {
        Dummy.context
    }

    var delegate: ActionComponentDelegate?

    var onHandle: ((_ action: RedirectAction) -> Void)?

    func handle(_ action: RedirectAction) {
        onHandle?(action)
    }
}
