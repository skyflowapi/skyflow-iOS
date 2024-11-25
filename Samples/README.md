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
5. Move the downloaded “credentials.json” file #Create a service account account into the bearer-token-generator directory.        
6. Create `index.js` file
7. Open `index.js` file
8. populate `index.js` file with below code snippet
```javascript
const express = require("express");
const app = express();
const cors = require("cors");
const port = 3000;
const {
   generateBearerToken,
   isExpired
} = require("skyflow-node");

app.use(cors());

let filepath = "credentials.json";
let bearerToken = "";

const getSkyflowBearerToken = () => {
   return new Promise(async (resolve, reject) => {
       try {
           if (!isExpired(bearerToken)) {
               resolve(bearerToken);
           }
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
app.get("/", async (req, res) => {
 let bearerToken = await getSkyflowBearerToken();
 res.json({"accessToken" : bearerToken});
});

app.listen(port, () => {
 console.log(`Server is listening on port ${port}`);
})
```
9. Start the server

        node index.js
    server will start at `localhost:3000`
10. Your **<TOKEN_END_POINT_URL>** with `http://localhost:3000/`

## The samples
### Collect and reveal
This sample demonstrates how to use Skyflow Elements to collect sensitive user information and reveal it to a user.
#### Configure
1. In `Skyflow.Configuration()` of [ViewController.swift](CollectAndRevealSample/CollectAndRevealSample/ViewController.swift), replace with the following fields:
         - The placeholder "<VAULT_ID>" with the vault ID you noted previously.
         - The placeholder "<VAULT_URL>" with the vault URL you noted previously.
2. Replace the placeholder "<TOKEN_END_POINT_URL>" in [ExampleTokenProvider.swift](https://github.com/skyflowapi/skyflow-iOS/blob/SDK-753-update-sample-app-readme/Samples/CollectAndRevealSample/CollectAndRevealSample/ExampleTokenProvider.swift) with the service account bearer token endpoint. 
 
#### Running the sample
    1. Open CMD
    2. Navigate to CollectAndRevealSample
    3. Run 

            pod install
    4. Open the CollectAndRevealSample.xcworkspace file using xcode.
    5. Build and run using command + R.
    
### Custom validation
This sample demonstrates how to apply custom validation rules to Skyflow elements to restrict the type of input a user can provide.
#### Configure
In `Skyflow.Configuration()` of [ViewController.swift](Validations/Validations/ViewController.swift), replace with the following fields:
1. Replace the placeholder "<VAULT_ID>" in the configuration with the vault ID previously noted. Replace the placeholder "<VAULT_URL>" with the vault URL previously noted.
2. Replace the placeholder "<TOKEN_END_POINT_URL>" in [ExampleTokenProvider.swift](https://github.com/skyflowapi/skyflow-iOS/blob/SDK-753-update-sample-app-readme/Samples/Validations/Validations/ExampleTokenProvider.swift) with the service account bearer token endpoint.

#### Running the sample
      1. Open CMD
      2. Navigate to Validations
      3. Run 
            
             pod install
      4. Open the Validations.xcworkspace file using xcode
      5. Build and run using command + R.
