/*
 * Copyright (c) 2026 Skyflow
*/

// SK-2963: detection logic for the beta-build-in-prod startup warning.

import Foundation

// Beta/dev builds are published as <major>.<minor>.<patch>-beta.<n> or
// -dev.<sha>; a plain public release has no suffix.
internal func isNonGaVersion(_ version: String) -> Bool {
    return version.range(of: "^\\d+\\.\\d+\\.\\d+$", options: .regularExpression) == nil
}

// options.env has no effect on which domain this SDK talks to (it's a decorative
// DEV/PROD toggle only used to suppress a couple of setValue()/clearValue() warnings -
// see TextField.swift/StateforText.swift), so it can't be trusted to tell us whether a
// vault is Production. vaultURL is the one thing the customer sets that actually points
// at their real vault - if it doesn't carry one of the non-prod domain markers, treat it
// as pointed at Production, the same conservative "default to prod" every server SDK's
// own Env-to-domain mapping uses.
internal func isNonProdVaultUrl(_ vaultURL: String) -> Bool {
    if vaultURL.isEmpty { return false }
    return vaultURL.range(of: "(-preview|\\.dev|\\.tech)", options: .regularExpression) != nil
}
