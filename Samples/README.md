# Samples

Sample apps are organized by SDK — pick the folder for the product you use.

## [`Skyflow/`](Skyflow/) — legacy Skyflow SDK (`pod 'Skyflow'` / `import Skyflow`)

| Sample | Demonstrates |
|---|---|
| [CollectAndRevealSample](Skyflow/CollectAndRevealSample/) | Collecting card data with secure elements and revealing tokens (incl. card brand choice) |
| [ComposableElements](Skyflow/ComposableElements/) | Multiple fields composed into one container/row |
| [InputFormatting](Skyflow/InputFormatting/) | Format/translation patterns on collect elements |
| [UpsertFeature](Skyflow/UpsertFeature/) | Insert with upsert options |
| [Validations](Skyflow/Validations/) | Built-in and custom validation rules |

## [`SkyflowFlowVaultIOS/`](SkyflowFlowVaultIOS/) — Skyflow FlowVault SDK (`pod 'Skyflow-flowvault-ios'` / `import SkyflowFlowVaultIOS`)

| Sample | Demonstrates |
|---|---|
| [UpdateDataUsingElements](SkyflowFlowVaultIOS/UpdateDataUsingElements/) | Updating vault records via collect elements with `skyflowId`; its Podfile also shows installing **both** SDKs side by side in one app |

## Running a sample

- Navigate to the desired sample (`Samples/<SDK>/<SampleName>`)
- In CMD, run the command, pod install
- Open the .xcworkspace file using xcode
- Click on Build and run

Most Podfiles reference the published pods. `UpdateDataUsingElements` uses
`:path => '../../../'` to build the SDKs from this repository checkout —
useful for testing local changes.

`Note`:
In every sample, in the Skyflow configuration, replace the following fields:
1. Replace the placeholder "<VAULT_ID>" with the correct vaultId you want to connect
2. Replace the placeholder "<VAULT_URL>" with the correct vaultURL
3. Implement the bearer token endpoint using server side auth SDK and service account file.
   Replace the placeholder "<TOKEN_END_POINT_URL>" with the  bearer token endpoint which gives the bearerToken, implemented at your backend.
