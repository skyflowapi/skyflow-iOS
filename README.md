# skyflow-iOS
---
Skyflow’s iOS SDK can be used to securely collect, tokenize, and display sensitive data in the mobile without exposing your front-end infrastructure to sensitive data. 

# Table of Contents
- [**Installing Skyflow-iOS**](#installing-skyflow-iOS) 
- [**Initializing Skyflow-iOS**](#initializing-skyflow-iOS)
- [**Securely collecting data client-side**](#securely-collecting-data-client-side)
- [**Securely revealing data client-side**](#securely-revealing-data-client-side)

# Installing skyflow-iOS
---
### SPM (Swift Package Manager)
- Go to File -> Swift Packages -> New Package Dependency (in Xcode IDE)
- Enter https://github.com/skyflowapi/skyflow-iOS.git and press ok.

### Cocoapods
- To integrate skyflow-iOS into your Xcode project using CocoaPods, specify it in your Podfile:
    ```
    pod 'skyflow-iOS'
    ```


# Initializing skyflow-iOS
----
Use the ```initialize()``` method to initialize a Skyflow client as shown below. 
```swift
let demoTokenProvider = DemoTokenProvider() //DemoTokenProvider is an implementation of the Skyflow.TokenProvider protocol

let config = Skyflow.Configuration(vaultID: <VAULT_ID>, vaultURL: <VAULT_URL>, tokenProvider: demoTokenProvider)

let skyflowClient = Skyflow.initialize(config)
```

For the tokenProvider parameter, pass in an implementation of the Skyflow.TokenProvider protocol that declares a getBearerToken method which retrieves a Skyflow bearer token from your backend. This function will be invoked when the SDK needs to insert or retrieve data from the vault.

For example, if the response of the consumer tokenAPI is in the below format

```java
{
   "accessToken": string,
   "tokenType": string
}
```

then, your Skyflow.TokenProvider Implementation should be as below

```swift
public class DemoTokenProvider : Skyflow.TokenProvider {
    public func getBearerToken(_ apiCallback: Skyflow.Callback) {
        if let url = URL(string: <YOUR_TOKEN_ENDPOINT>) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url){ data, response, error in
                if(error != nil){
                    print(error!)
                    return
                }
                if let safeData = data {
                    do {
                        let x = try JSONSerialization.jsonObject(with: safeData, options:[]) as? [String: String]
                        if let accessToken = x?["accessToken"] {
                            apiCallback.onSuccess(accessToken)
                        }
                    }
                    catch {
                        apiCallback.onFailure(error)
                    }
                }
            }
            task.resume()
        }
    }
}
```

NOTE: You should pass access token as `String` value in the success callback of getBearerToken.

---
# Securely collecting data client-side
-  [**Inserting data into the vault**](#inserting-data-into-the-vault)
-  [**Using Skyflow Elements to collect data**](#using-skyflow-elements-to-collect-data)

## Inserting data into the vault

To insert data into the vault from the integrated application, use the ```insert(records: [String: Any], options: InsertOptions?= InsertOptions() , callback: Skyflow.Callback)``` method of the Skyflow client. The records parameter takes an array of records to be inserted into the vault. The options parameter takes a Skyflow.InsertOptions object. See below:

```swift
let records = [
  [
    table: "string",    //table into which record should be inserted
    fields: [                         
      column1 : "value",    //column names should match vault column names
      //...additional fields here
    ]
  ]
  //...additional records here
]
let insertOptions = Skyflow.InsertOptions(tokens: false) //indicates whether or not tokens should be returned for the inserted data. Defaults to 'true'
let insertCallback = InsertCallback()       //Custom callback - implementation of Skyflow.Callback
skyflowClient.insert(records: records, options: insertOptions, callback: insertCallback)
```

An example of an insert call is given below: 

```swift
let insertCallback = InsertCallback()     //Custom callback - implementation of Skyflow.Callback
skyflowClient.insert(records: [
  [
    "table": "cards",
    "fields": [
        "cardNumber": "41111111111",
        "cvv": "123",
    ]
  ]],
  callback: insertCallback);
```

**Response :**
```json
{
  "records": [
    {
     "table": "cards",
     "fields":{
        "cardNumber": "f3907186-e7e2-466f-91e5-48e12c2bcbc1",
        "cvv": "1989cb56-63da-4482-a2df-1f74cd0dd1a5"
      }
    }
  ]
}
```

## Using Skyflow Elements to collect data

**Skyflow Elements** provide developers with pre-built form elements to securely collect sensitive data client-side.  This reduces your PCI compliance scope by not exposing your front-end application to sensitive data. Follow the steps below to securely collect data with Skyflow Elements in your application.

### Step 1: Create a container

First create a **container** for the form elements using the ```skyflowClient.container(type: Skyflow.ContainerType)``` method as show below

```swift
let container = skyflowClient.container(type: Skyflow.ContainerType.COLLECT)
```

### Step 2: Create a collect Element
To create a collect Element, we must first construct a Skyflow.CollectElementInput object defined as shown below:

```swift
let collectElementInput =  Skyflow.CollectElementInput(
   table: "string",            //the table this data belongs to
   column: "string",           //the column into which this data should be inserted
   styles: Skyflow.Styles,     //optional styles that should be applied to the form element
   label: "string",            //optional label for the form element
   placeholder: "string",      //optional placeholder for the form element
   type: Skyflow.ElementType   //Skyflow.ElementType enum
)
```
The `table` and `column` parameters indicate which table and column in the vault the Element corresponds to.
Note: Use dot delimited strings to specify columns nested inside JSON fields (e.g. address.street.line1).

The `styles` parameter accepts a Skyflow.Styles object which consists of multiple `Skyflow.Style` objects which should be applied to the form element in the following states:

- `base`: all other variants inherit from these styles
- `complete`: applied when the Element has valid input
- `empty`: applied when the Element has no input
- `focus`: applied when the Element has focus
- `invalid`: applied when the Element has invalid input

Each Style object accepts the following properties, please note that each property is optional:

```swift
let style = Skyflow.Style(
borderColor: UIColor,            //optional
cornerRadius: CGFloat,           //optional
padding: UIEdgeInsets,           //optional
borderWidth: CGFloat,            //optional
font:  UIFont,                   //optional
textAlignment: NSTextAlignment,  //optional
textColor: UIColor               //optional
)
```

An example Skyflow.Styles object
```swift
let styles = Skyflow.Styles(
base: style,                    //optional
complete: style,                //optional
empty: style,                   //optional
focus: style,                   //optional
invalid: style                  //optional
)
```

Finally, the `type` parameter takes a Skyflow.ElementType. Each type applies the appropriate regex and validations to the form element. There are currently 4 types:
- `CARDHOLDER_NAME`
- `CARD_NUMBER`
- `EXPIRATION_DATE`
- `CVV`

Once the `Skyflow.CollectElementInput` and `Skyflow.CollectElementOptions` objects are defined, add to the container using the ```create(input: CollectElementInput, options: CollectElementOptions)``` method as shown below. The `input` param takes a Skyflow.CollectElementInput object as defined above and the `options` parameter takes an Skyflow.CollectElementOptions object as described below:

```swift
let collectElementInput =  Skyflow.CollectElementInput(
   table: "string",            //the table this data belongs to
   column: "string",           //the column into which this data should be inserted
   styles: Skyflow.Styles,     //optional, styles that should be applied to the form element
   label: "string",            //optional, label for the form element
   placeholder: "string",      //optional, placeholder for the form element
   type: Skyflow.ElementType   //Skyflow.ElementType enum
)

let collectElementOptions = Skyflow.CollectElementOptions(
  required: false  //indicates whether the field is marked as required. Defaults to 'false'
)

const element = container.create(input: collectElementInput, options: collectElementOptions)
```



### Step 3: Mount Elements to the Screen

To specify where the Elements will be rendered on the screen, create a parent UIView (like UIStackView, etc) and you can add it as a subview programmatically.

```swift
let stackView = UIStackView()
stackView.addArrangedSubview(element)
```

The Skyflow Element is an implementation of the UIView so it can be used/mounted similarly.

#### Step 4 :  Collect data from Elements
When the form is ready to be submitted, call the `collect(options: Skyflow.InsertOptions? = nil, callback: Skyflow.Callback)` method on the container object. The options parameter takes a Skyflow.InsertOptions object as shown below:
```swift
let options = Skyflow.InsertOptions(tokens: true) //indicates whether tokens for the collected data should be returned. Defaults to 'true'
let insertCallback = InsertCallback() //Custom callback - implementation of Skyflow.callback
container.collect(options: options, callback: insertCallback)
```
### End to end example of collecting data with Skyflow Elements

#### Sample Code:
```swift
//Initialize skyflow configuration
let config = Skyflow.Configuration(vaultID: VAULT_ID, vaultURL: VAULT_URL, tokenProvider: demoTokenProvider)
 
//Initialize skyflow client
let skyflowClient = Skyflow.initialize(config)
 
//Create a CollectContainer
let container = skyflowClient.container(type: Skyflow.ContainerType.COLLECT)
 
//Initialize and set required options
let options = Skyflow.CollectElementOptions(required: true)
 
//Create Skyflow.Styles with individual Skyflow.Style variants
let baseStyle = Skyflow.Style(borderColor: UIColor.blue)
let completedStyle = Skyflow.Style(borderColor: UIColor.green)
let styles = Skyflow.Styles(base: baseStyle, completed: completedStyle)
 
//Create a CollectElementInput
let input = Skyflow.CollectElementInput(table: "cards", column: "cardNumber", styles: styles, label: "card number", placeholder: "card number", type: Skyflow.ElementType.CARD_NUMBER)
 
//Create a CollectElementOptions instance
let options = Skyflow.CollectElementOptions(required: true)
 
//Create a Collect Element from the Collect Container
let skyflowElement = container.create(input, options)
 
//Can interact with this object as a normal UIView Object and add to View
 
//Initialize and set required options for insertion
let insertOptions = Skyflow.InsertOptions(tokens: true)
 
//Implement a custom Skyflow.Callback to be called on Insertion success/failure
public class InsertCallback: Skyflow.Callback {
  public func onSuccess(_ responseBody: Any) {
      print(responseBody)
  }
   public func onFailure(_ error: Error) {
      print(error)
  }
}
 
//Initialize custom Skyflow.Callback
let insertCallback = InsertCallback()
 
//Call collect method on CollectContainer
container.collect(options: insertOptions, callback: insertCallback)

```
#### Sample Response :
```
{
  "records": [
    {
      "table": "cards",
      "fields": {
        "cardNumber": "f3907186-e7e2-466f-91e5-48e12c2bcbc1"
      }
    }
  ]
}

```
---
# Securely revealing data client-side
-  [**Retrieving data from the vault**](#retrieving-data-from-the-vault)
-  [**Using Skyflow Elements to reveal data**](#using-skyflow-elements-to-reveal-data)

## Retrieving data from the vault
For non-PCI use-cases, to retrieve data from the vault and reveal it in the mobile, use the `get(records)` method. The records parameter takes an array of `records` to be fetched as shown below.
```swift
let records = [
    "records": [
      [ 
        "id": "string",                       //Token for the record to be fetched
        "redaction": Skyflow.RedactionType    //redaction to be applied to the retrieved data
      ]
    ]
]

```
There are four enum values in Skyflow.RedactionType: 
- `PLAIN_TEXT`
- `MASKED`
- `REDACTED`
- `DEFAULT`

An example of a get call:
```swift
let getCallback = GetCallback() //Custom callback - implementation of Skyflow.Callback

skyflowClient.get(records: [
     "records": [
        [
         "id": "131e70dc-6f76-4319-bdd3-96281e051051",
         "redaction": Skyflow.RedactionType.PLAIN_TEXT
        ]
      ]
    ],
    callback: getCallback
)
```
The sample response:
```json
{
  "records": [
    {
      "id": "131e70dc-6f76-4319-bdd3-96281e051051",
      "date_of_birth": "1990-01-01",
    }
  ]
}
```

## Using Skyflow Elements to reveal data
Skyflow Elements can be used to securely reveal data in an application without exposing your front end to the sensitive data. This is great for use-cases like card issuance where you may want to reveal the card number to a user without increasing your PCI compliance scope.
### Step 1: Create a container
To start, create a container using the `skyflowClient.container(Skyflow.ContainerType.REVEAL)` method as shown below.
```swift
    let container = skyflowClient.container(type: Skyflow.ContainerType.REVEAL)
```

### Step 2: Create a reveal Element
To create a reveal Element, we must first construct a Skyflow.RevealElementInput object defined as shown below:

```swift
let revealElementInput = Skyflow.RevealElementInput(
    id: "string", 
    styles: Skyflow.Styles,        //optional, styles to be applied to the element
    label: "string",               //optional, label for the element
    redaction: Skyflow.RedactionType
)
```
The `styles` parameter accepts a styles object as described in the [previous section](#step-2-create-a-collect-element) for collecting data but the only state available for a reveal element is the base state. For a list of acceptable redaction types, see the [section above](#Retrieving-data-from-the-vault).

Once you've defined a Skyflow.RevealElementInput object, you can use the `create(element)` method of the container to create the Element as shown below: 

```swift
let element = container.create(input: revealElementInput)
```

### Step 3: Mount Elements to the Screen

Elements used for revealing data are mounted to the screen the same way as Elements used for collecting data. Refer to Step 3 of the [section above](#step-3-mount-elements-to-the-screen).

### Step 4: Reveal data
When the sensitive data is ready to be retrieved and revealed, call the `reveal()` method on the container as shown below:
```swift
let revealCallback = RevealCallback()  //Custom callback - implementation of Skyflow.Callback
container.reveal(callback: revealCallback)
```

### End to end example of revealing data with Skyflow Elements
#### Sample Code:
```swift
//Initialize skyflow configuration
let config = Skyflow.Configuration(vaultID: <VAULT_ID>, vaultURL: <VAULT_URL>, tokenProvider: demoTokenProvider)
 
//Initialize skyflow client
let skyflowClient = Skyflow.initialize(config)
 
//Create a Reveal Container
let container = skyflowClient.container(type: Skyflow.ContainerType.REVEAL)

//Create Skyflow.Styles with individual Skyflow.Style variants
let baseStyle = Skyflow.Style(borderColor: UIColor.blue)
let styles = Skyflow.Styles(base: baseStyle)
 
//Create Reveal Elements
let cardNumberInput = Skyflow.RevealElementInput(
id: "b63ec4e0-bbad-4e43-96e6-6bd50f483f75",
styles: styles,
label: "cardnumber",
redaction: Skyflow.RedactionType.PLAIN_TEXT
)

let cardNumberElement = container.create(input: cardNumberInput)

let cvvInput = Skyflow.RevealElementInput(
id: "89024714-6a26-4256-b9d4-55ad69aa4047",
styles: styles,
label: "cvv",
redaction: Skyflow.RedactionType.PLAIN_TEXT
)

let cvvElement = container.create(input: cvvInput)

//Can interact with these objects as a normal UIView Object and add to View
 
//Implement a custom Skyflow.Callback to be called on Reveal success/failure
public class RevealCallback: Skyflow.Callback {
  public func onSuccess(_ responseBody: Any) {
      print(responseBody)
  }
   public func onFailure(_ error: Error) {
      print(error)
  }
}
 
//Initialize custom Skyflow.Callback
let revealCallback = RevealCallback()
 
//Call reveal method on RevealContainer
container.reveal(callback: revealCallback)

```

The response below shows that some tokens assigned to the reveal elements get revealed successfully, while others fail and remain unrevealed.

#### Sample Response:
```json
{
  "success": [
    {
      "id": "b63ec4e0-bbad-4e43-96e6-6bd50f483f75"
    }
  ],
 "errors": [
    {
       "id": "89024714-6a26-4256-b9d4-55ad69aa4047",
       "error": {
         "code": 404,
         "description": "Tokens not found for 89024714-6a26-4256-b9d4-55ad69aa4047"
       } 
   }   
  ]
}
```
