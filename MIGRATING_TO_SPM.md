# Migrating from CocoaPods to Swift Package Manager

CocoaPods trunk became read-only on **December 2, 2026**. Versions already published there keep installing, but new versions of `Skyflow` and `SkyflowFlowVault` are released only through **Swift Package Manager (SPM)**.

To keep receiving updates and fixes, move your app from CocoaPods to SPM. The SDK API does not change: your `import` statements and code stay the same, including qualified names such as `Skyflow.Styles` or `SkyflowFlowVault.Configuration`.

| | CocoaPods (frozen) | SPM |
|---|---|---|
| Last / current version | 1.26.0 | 1.26.0 and later |
| Package URL | — | `https://github.com/skyflowapi/skyflow-iOS.git` |
| PDB vault SDK | `pod 'Skyflow'` | product `Skyflow` |
| Flow vault SDK | `pod 'SkyflowFlowVault'` | product `SkyflowFlowVault` |
| Import | `import Skyflow` / `import SkyflowFlowVault` | unchanged |
| Minimum iOS | 13.0 | 13.0 |

## Before you start

- Use **Xcode 15 or later**. The package requires the Swift 5.9 toolchain.
- Note the version in your `Podfile.lock`, for example `Skyflow (1.25.1)`. Start SPM on the same version so the migration changes only how the SDK is installed. Upgrade the SDK separately afterwards.
- Commit or stash your work so you can easily compare and roll back.

## Step 1: Remove the pod

1. In your `Podfile`, delete the Skyflow line:
   ```diff
   target 'YourApp' do
   -  pod 'Skyflow', '1.25.1'
      pod 'SomeOtherPod'
   end
   ```
2. Run:
   ```sh
   pod install
   ```

**If Skyflow was your only pod**, remove CocoaPods from the project entirely:
```sh
pod deintegrate          # from the cocoapods-deintegrate plugin, bundled with CocoaPods
rm -rf Podfile Podfile.lock Pods YourApp.xcworkspace
```
From now on, open `YourApp.xcodeproj` instead of the `.xcworkspace`.

**If you use other pods**, keep using the `.xcworkspace`. CocoaPods and SPM can be used in the same project.

## Step 2: Add the Swift package

### Xcode project

1. Open the project and choose **File → Add Package Dependencies…**
2. Enter `https://github.com/skyflowapi/skyflow-iOS.git`.
3. Set **Dependency Rule** to one of:
   - **Exact Version** with your current version, e.g. `1.25.1`. Recommended for the migration itself.
   - **Up to Next Major Version** starting from your current version, to receive minor and patch updates automatically.
4. Click **Add Package**.
5. In **Choose Package Products**, select only the product you were using and add it to your app target:
   - `Skyflow` if you had `pod 'Skyflow'`
   - `SkyflowFlowVault` if you had `pod 'SkyflowFlowVault'`

   Do not add `SkyflowCore`. It is an internal module that both products already include.

### Swift package (`Package.swift`)

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "YourPackage",
    platforms: [.iOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/skyflowapi/skyflow-iOS.git", exact: "1.25.1")
    ],
    targets: [
        .target(
            name: "YourPackage",
            dependencies: [
                .product(name: "Skyflow", package: "skyflow-iOS")
                // or: .product(name: "SkyflowFlowVault", package: "skyflow-iOS")
            ]
        )
    ]
)
```

## Step 3: Build and verify

1. Clean the build folder (**Product → Clean Build Folder**, ⇧⌘K) and build.
2. Run the app and check the screens that use Skyflow elements:
   - Collect and reveal elements render and submit as before.
   - The card-brand icon and the copy / success icons appear. These images are loaded from the package's resource bundle.
3. Commit `Package.resolved`. It is located at `YourApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`, or inside the `.xcworkspace` if you still use CocoaPods. It pins the exact SDK commit so that every machine and CI builds the same version.

## Step 4: Update CI

- Remove the `pod install` step if Skyflow was your only pod.
- Resolve packages before building, so that network problems fail early and clearly:
  ```sh
  xcodebuild -resolvePackageDependencies -project YourApp.xcodeproj -scheme YourApp
  ```
- To cache packages between CI runs, cache the directory you pass to `-clonedSourcePackagesDirPath`.

## Upgrading after the migration

- **Xcode:** right-click the package in the Project navigator → **Update Package**, or change the dependency rule in **Project → Package Dependencies**.
- **`Package.swift`:** change the version, then run `swift package update`.
- **Beta versions** (`X.Y.Z-beta.N`) are never selected by a version range. Use **Exact Version**, e.g. `exact: "1.27.0-beta.1"`.

Release notes for every version are on the [GitHub Releases page](https://github.com/skyflowapi/skyflow-iOS/releases).

## Troubleshooting

**`No such module 'Skyflow'` (or `'SkyflowFlowVault'`)**
The product is not linked to the target that imports it. In the target's **General → Frameworks, Libraries, and Embedded Content**, click **+** and add the product. For a `Package.swift`, add the `.product(...)` entry to that target's `dependencies`.

**Duplicate symbol, or "ambiguous" type errors**
The SDK is installed through both CocoaPods and SPM. Make sure the pod is removed from the `Podfile`, run `pod install`, then clean the build folder.

**Card-brand or copy icons are missing**
Make sure no leftover CocoaPods build products remain: run `pod deintegrate` (or `pod install` after removing the pod), delete DerivedData, and rebuild. Under SPM, the SDK loads its images from its own package resource bundle. Nothing needs to be added to your app's assets.

**`Package resolution failed` / cannot fetch the package**
Check that the URL is exactly `https://github.com/skyflowapi/skyflow-iOS.git` and that the version you entered exists as a [release tag](https://github.com/skyflowapi/skyflow-iOS/tags). Version tags have no `v` prefix (`1.26.0`, not `v1.26.0`). If you are behind a proxy, make sure Xcode can reach `github.com`.

**I need to stay on CocoaPods for now**
Versions already on trunk (up to 1.26.0) remain installable with `pod 'Skyflow'` or `pod 'SkyflowFlowVault'`, but you will not receive any later releases, including security fixes. Plan your migration to SPM.

## Need help?

Open an issue at [github.com/skyflowapi/skyflow-iOS/issues](https://github.com/skyflowapi/skyflow-iOS/issues) or contact Skyflow support.
