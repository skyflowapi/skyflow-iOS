Please follow these below steps to run samples

- Navigate to the desired sample
- In CMD, run the command, pod install
- Open the .xcworkspace file using xcode
- Click on Build and run

`Note`:
In every sample, in Skyflow.Config(), replace with the following fields:
1. Replace the placeholder "<VAULT_ID>" with the correct vaultId you want to connect
2. Replace the placeholder "<VAULT_URL>" with the correct vaultURL
3. Implement the bearer token endpoint using server side auth SDK and service account file.
   Replace the placeholder "<TOKEN_END_POINT_URL>" with the  bearer token endpoint which gives the bearerToken, implemented at your backend. 