Please follow these steps to run samples.

## Recommended (SPM)

- Navigate to the desired sample.
- Open the `.xcodeproj` file in Xcode.
- Add package dependency: `https://github.com/skyflowapi/skyflow-iOS.git`.
- Select the `Skyflow` product for the sample target.
- Build and run.

## Existing CocoaPods flow

- Navigate to the desired sample.
- In terminal, run `pod install`.
- Open the `.xcworkspace` file in Xcode.
- Build and run.

For migration steps and risk checks, see [CocoaPods → Swift Package Manager (SPM) Migration Guide](../docs/cocoapods-to-spm-migration.md).

`Note`:
In every sample, in Skyflow.Config(), replace with the following fields:
1. Replace the placeholder "<VAULT_ID>" with the correct vaultId you want to connect
2. Replace the placeholder "<VAULT_URL>" with the correct vaultURL
3. Implement the bearer token endpoint using server side auth SDK and service account file.
   Replace the placeholder "<TOKEN_END_POINT_URL>" with the  bearer token endpoint which gives the bearerToken, implemented at your backend. 