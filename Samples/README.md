# iOS SDK samples
Test the SDK by adding `VAULT-ID`, `VAULT-URL`, and `SERVICE-ACCOUNT` details in the required places for each sample.

### Prerequisites
- iOS 13.0.0 or higher
- [cocoapods](https://cocoapods.org)
- Xcode
- [Node.js](https://nodejs.org/en/) 10 or higher
- [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) 6.x.x or higher

- [express.js](http://expressjs.com/en/starter/hello-world.html)


### Create the vault
1.  In a browser, sign in to Skyflow Studio.
2. Create a vault by clicking **Create Vault** > **Start With a Template** > **PIIData**.
3. Once the vault is ready, click the gear icon and select **Edit Vault Details**.
4. Note your **Vault URL** and **Vault ID** values, then click Cancel. You'll need these later.

### Create a service account
1. In the side navigation click, **IAM** > **Service Accounts** > **New Service Account**.
2. For **Name**, enter "SDK Samples". For Roles, choose **Vault Editor**.
3. Click **Create**. Your browser downloads a **credentials.json** file. Keep this file secure. You'll need it to generate bearer tokens.

### Create a bearer token generation endpoint
1. Create a new directory named `bearer-token-generator`.

        mkdir bearer-token-generator
2. Navigate to `bearer-token-generator` directory.

        cd bearer-token-generator
3. Initialize npm

        npm init
4. Install `skyflow-node`

        npm i skyflow-node
5. Create `index.js` file
6. Open `index.js` file
7. populate `index.js` file with below code snippet
```javascript
const express = require('express')
const app = express()
var cors = require('cors')
const port = 3000
const {
    generateBearerToken,
    isExpired
} = require('skyflow-node');

app.use(cors())

let filepath = 'cred.json';
let bearerToken = "";

function getSkyflowBearerToken() {
    return new Promise(async (resolve, reject) => {
        try {
            if (!isExpired(bearerToken)) resolve(bearerToken)
            else {
                let response = await generateBearerToken(filepath);
                bearerToken = response.accessToken;
                resolve(bearerToken);
            }
        } catch (e) {
            reject(e);
        }
    });
}

app.get('/', async (req, res) => {
  let bearerToken = await getSkyflowBearerToken();
  res.json({"accessToken" : bearerToken});
})

app.listen(port, () => {
  console.log(`Server is listening on port ${port}`)
})
```
8. Start the server

        node index.js
    server will start at `localhost:3000`
9. Your **<TOKEN_END_POINT_URL>** with `http://localhost:3000/`

## The samples
### Collect and reveal
This sample illustrates how to use secure Skyflow elements to collect sensitive user information and reveal it to the user via tokens.
#### Configure
1. In `Skyflow.Configuration()` of [ViewController.swift](CollectAndRevealSample/CollectAndRevealSample/ViewController.swift), replace with the following fields:
         - Replace the placeholder "<VAULT_ID>" with the correct vaultId you want to connect
         - Replace the placeholder "<VAULT_URL>" with the correct vaultURL
2. Update `Fields` struct in [ResponseStructs.swift](CollectAndRevealSample/CollectAndRevealSample/ResponseStructs.swift) with field name of used vault. For ex: 
        
        ```swift
            struct Fields: Codable {
               let name: NameField
               let cvv: String
               let cardExpiration: String
               let cardNumber: String
               let skyflow_id: String
            }
        ```
        
    The fields can be different depending upon the vault.
3. Update 
4. Replace the placeholder "<TOKEN_END_POINT_URL>" of [ExampleTokenProvider.swift](CollectAndRevealSample/CollectAndRevealSample/ExampleTokenProvider.swift) with the  bearer token endpoint which gives the bearerToken, implemented at your backend or `http://localhost:3000/`.
 5. Running the sample
    1. Open CMD
    2. Navigate to `CollectAndRevealSample`
    3. Run 

            pod install
    4. Open the [`CollectAndRevealSample.xcworkspace](`CollectAndRevealSample/`CollectAndRevealSample.xcworkspace) file using xcode
    5. click on build and run

### Validations
This sample illustrates how to apply custom validation rules on secure Skyflow Collect elements to restrict the type of input a user can provide.
#### Configure
1. In `Skyflow.Configuration()` of [ViewController.swift](Validations/Validations/ViewController.swift), replace with the following fields:
2. Replace the placeholder "<VAULT_ID>" in the configuration with the correct vaultId you want to connect
3. Replace the placeholder "<VAULT_URL>" with the correct vaultURL
4. Replace the placeholder "<TOKEN_END_POINT_URL>" in [ExampleTokenProvider.swift](Validations/Validations/ExampleTokenProvider.swift) with the  bearer token endpoint which gives the bearerToken, implemented at your backend or `http://localhost:3000/`.
5. Running the sample
      1. Open CMD
      2. Navigate to `Validations`
      3. Run 
            
             pod install
      4. Open the [Validations.xcworkspace](Validations/Validations.xcworkspace) file using xcode
      5. click on build and run
