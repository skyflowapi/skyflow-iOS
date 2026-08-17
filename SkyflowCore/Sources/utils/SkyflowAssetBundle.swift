/*
 * Copyright (c) 2022 Skyflow
*/

// CocoaPods resource-bundle name for asset lookups in the shared core.
// Both pods ship their assets as "Skyflow.bundle" (declared in each podspec's
// resource_bundles) so the lookup is identical regardless of which product is
// built. (SPM builds use Bundle.module instead and never hit this path.)

import Foundation

package enum SkyflowAssetBundle {
    package static let name = "Skyflow.bundle"
}
