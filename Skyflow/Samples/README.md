# Samples

Sample apps for the Skyflow SDK (`pod 'Skyflow'` / `import Skyflow`):

| Sample | Description |
|--------|-------------|
| [CollectAndRevealSample](CollectAndRevealSample/) | Collect card data with secure elements and reveal tokens back to values (includes card brand choice) |
| [ComposableElements](ComposableElements/) | Lay out multiple secure elements together in shared rows using a composable container |
| [GetSample](GetSample/) | Fetch records by skyflow ID or unique column values using `get()`/`getById()` |
| [InputFormatting](InputFormatting/) | Apply `format`/`translation` patterns to control how element input is displayed |
| [UpdateDataUsingElements](UpdateDataUsingElements/) | Update existing vault records through collect elements using a skyflow ID |
| [UpsertFeature](UpsertFeature/) | Insert-or-update records with upsert options on a unique column |
| [Validations](Validations/) | Built-in and custom validation rules (regex, length, element match) on collect elements |

## Running a sample

Please follow these below steps to run samples

- Navigate to the desired sample
- In CMD, run the command, pod install
- Open the .xcworkspace file using xcode
- Click on Build and run

`Note`:
In every sample, in Skyflow.Configuration(), replace with the following fields:
1. Replace the placeholder "<VAULT_ID>" with the correct vaultId you want to connect
2. Replace the placeholder "<VAULT_URL>" with the correct vaultURL
3. Implement the bearer token endpoint using server side auth SDK and service account file.
   Replace the placeholder "<TOKEN_END_POINT_URL>" with the  bearer token endpoint which gives the bearerToken, implemented at your backend. 