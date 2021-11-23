# skyflow-iOS
---
Skyflow’s iOS SDK can be used to securely collect, tokenize, and display sensitive data in the mobile without exposing your front-end infrastructure to sensitive data. 

# Table of Contents
- [**Installing Skyflow-iOS**](#installing-skyflow-iOS) 
- [**Initializing Skyflow-iOS**](#initializing-skyflow-iOS)
- [**Securely collecting data client-side**](#securely-collecting-data-client-side)
- [**Securely revealing data client-side**](#securely-revealing-data-client-side)
- [**Securely invoking connection client-side**](#Securely-invoking-connection-client-side)

# Installing skyflow-iOS
---
### SPM (Swift Package Manager)
- Go to File -> Swift Packages -> New Package Dependency (in Xcode IDE)
- Enter https://github.com/skyflowapi/skyflow-iOS.git and press ok.

### Cocoapods
- To integrate skyflow-iOS into your Xcode project using CocoaPods, specify it in your Podfile:
    ```
    #Mentioning the below source will pick the podspec from Skyflow repo
    #Otherwise you can add cocoapod trunk as the source
    #source 'https://github.com/skyflowapi/skyflow-iOS-spec.git'
    
    pod 'Skyflow'
    ```


# Initializing skyflow-iOS
----
Use the ```initialize()``` method to initialize a Skyflow client as shown below. 
```swift
//DemoTokenProvider is an implementation of the Skyflow.TokenProvider protocol
let demoTokenProvider = DemoTokenProvider() 

let config = Skyflow.Configuration(
    vaultID: <VAULT_ID>,
    vaultURL: <VAULT_URL>,
    tokenProvider: demoTokenProvider,
    options: Skyflow.Options(
      logLevel: Skyflow.LogLevel,    // optional, if not specified default is ERROR 
      env: Skyflow.Env              // optional, if not specified default is PROD
    ) 
)

let skyflowClient = Skyflow.initialize(config)
```

For the tokenProvider parameter, pass in an implementation of the `Skyflow.TokenProvider` protocol that declares a getBearerToken method which retrieves a Skyflow bearer token from your backend. This function will be invoked when the SDK needs to insert or retrieve data from the vault.

For example, if the response of the consumer tokenAPI is in the below format

```
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

For `logLevel` parameter, there are 4 accepted values in Skyflow.LogLevel

- `DEBUG`
    
  When `Skyflow.LogLevel.DEBUG` is passed, all level of logs will be printed(DEBUG, INFO, WARN, ERROR).

- `INFO`

  When `Skyflow.LogLevel.INFO` is passed, INFO logs for every event that has occurred during the SDK flow execution will be printed along with WARN and ERROR logs.

- `WARN`

  When `Skyflow.LogLevel.WARN` is passed, WARN and ERROR logs will be printed.

- `ERROR`

  When `Skyflow.LogLevel.ERROR` is passed, only ERROR logs will be printed.

`Note`:
  - The ranking of logging levels is as follows :  DEBUG < INFO < WARN < ERROR
  - since `logLevel` is optional, by default the logLevel will be  `ERROR`.


For `env` parameter, there are 2 accepted values in Skyflow.Env

- `PROD`
- `DEV`

  In [Event Listeners](#event-listener-on-collect-elements), actual value of element can only be accessed inside the handler when the `env` is set to `DEV`.

`Note`:
  - since `env` is optional, by default the env will be  `PROD`.
  - Use `env` option with caution, make sure the env is set to `PROD` when using `skyflow-iOS` in production. 


---
# Securely collecting data client-side
-  [**Inserting data into the vault**](#inserting-data-into-the-vault)
-  [**Using Skyflow Elements to collect data**](#using-skyflow-elements-to-collect-data)
-  [**Using validations on Collect Elements**](#validations)
-  [**Event Listener on Collect Elements**](#event-listener-on-collect-elements)

## Inserting data into the vault

To insert data into the vault from the integrated application, use the ```insert(records: [String: Any], options: InsertOptions?= InsertOptions() , callback: Skyflow.Callback)``` method of the Skyflow client. The records parameter takes an array of records to be inserted into the vault. The options parameter takes a Skyflow.InsertOptions object. See below:

```swift
let records = [
  "records" : [[
    table: "string",        //table into which record should be inserted
    fields: [                         
      column1 : "value",    //column names should match vault column names
      //...additional fields here
    ]
  ]]
  //...additional records here
]
let insertOptions = Skyflow.InsertOptions(tokens: false) //indicates whether or not tokens should be returned for the inserted data. Defaults to 'true'
let insertCallback = InsertCallback()                   //Custom callback - implementation of Skyflow.Callback
skyflowClient.insert(records: records, options: insertOptions, callback: insertCallback)
```

An example of an insert call is given below: 

```swift
let insertCallback = InsertCallback()     //Custom callback - implementation of Skyflow.Callback
skyflowClient.insert(records: [
  "records": [[
    "table": "cards",
    "fields": [
        "cardNumber": "41111111111",
        "cvv": "123",
    ]
  ]]],
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
   table : String,                  //optional, the table this data belongs to
   column : String,                 //optional, the column into which this data should be inserted
   type: Skyflow.ElementType,       //Skyflow.ElementType enum
   inputStyles: Skyflow.Styles,     //optional styles that should be applied to the form element
   labelStyles: Skyflow.Styles,     //optional styles that will be applied to the label of the collect element
   errorTextStyles: Skyflow.Styles, //optional styles that will be applied to the errorText of the collect element
   label: String,                   //optional label for the form element
   placeholder: String,             //optional placeholder for the form element
   altText: String,                 //optional string that acts as an initial value for the collect element
   validations: ValidationSet       // optional set of validations for the input element
)
```
The `table` and `column` fields indicate which table and column in the vault the Element corresponds to. **Note**: 
-  Use dot delimited strings to specify columns nested inside JSON fields (e.g. `address.street.line1`)
-  `table` and `column` are optional only if the element is being used in invokeConnection()

The `inputStyles` parameter accepts a Skyflow.Styles object which consists of multiple `Skyflow.Styles` objects which should be applied to the form element in the following states:

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

The `labelStyles` and `errorTextStyles` fields accept the above mentioned `Skyflow.Styles` object which are applied to the `label` and `errorText` text views respectively.

The states that are available for `labelStyles` are `base` and `focus`.

The state that is available for `errorTextStyles` is only the `base` state, it shows up when there is some error in the collect element.

The parameters in `Skyflow.Style` object that are respected for `label` and `errorText` text views are
- padding
- font
- textColor
- textAlignment

Other parameters in the `Skyflow.Style` object are ignored for `label` and `errorText` text views.

Finally, the `type` parameter takes a Skyflow.ElementType. Each type applies the appropriate regex and validations to the form element. There are currently 5 types:
- `INPUT_FIELD`
- `CARDHOLDER_NAME`
- `CARD_NUMBER`
- `EXPIRATION_DATE`
- `CVV`
- `PIN`

The `INPUT_FIELD` type is a custom UI element without any built-in validations. See the section on [validations](#validations) for more information on validations.

Once the `Skyflow.CollectElementInput` and `Skyflow.CollectElementOptions` objects are defined, add to the container using the ```create(input: CollectElementInput, options: CollectElementOptions)``` method as shown below. The `input` param takes a `Skyflow.CollectElementInput` object as defined above and the `options` parameter takes an `Skyflow.CollectElementOptions` object as described below:

```swift
let collectElementInput =  Skyflow.CollectElementInput(
    table : String,                  //the table this data belongs to
    column : String,                 //the column into which this data should be inserted
    type: Skyflow.ElementType,       //Skyflow.ElementType enum
    inputStyles: Skyflow.Styles,     //optional styles that should be applied to the form element
    labelStyles: Skyflow.Styles,     //optional styles that will be applied to the label of the collect element
    errorTextStyles: Skyflow.Styles, //optional styles that will be applied to the errorText of the collect element
    label: String,                   //optional label for the form element
    placeholder: String,             //optional placeholder for the form element
    altText: String,                 //optional string that acts as an initial value for the collect element
    validations: ValidationSet       // optional set of validations for the input element
)

let collectElementOptions = Skyflow.CollectElementOptions(
  required: false  //indicates whether the field is marked as required. Defaults to 'false',
  enableCardIcon: true // indicates whether card icon should be enabled (only for CARD_NUMBER inputs)
)

const element = container.create(input: collectElementInput, options: collectElementOptions)
```



### Step 3: Mount Elements to the Screen

To specify where the Elements will be rendered on the screen, create a parent UIView (like UIStackView, etc) and you can add it as a subview programmatically.

```swift
let stackView = UIStackView()
stackView.addArrangedSubview(element)
```

The Skyflow Element is an implementation of the UIView so it can be used/mounted similarly. Alternatively, you can use the `unmount` method to reset any collect element to it's initial state

``` swift
func clearFieldsOnSubmit(_ elements: [TextField]) {
    // resets all elements in the array
    for element in elements {
        element.unmount()
    }
}
```

#### Step 4 :  Collect data from Elements
When the form is ready to be submitted, call the `collect(options: Skyflow.CollectOptions? = nil, callback: Skyflow.Callback)` method on the container object. The options parameter takes a `Skyflow.CollectOptions` object as shown below:
```swift
// Non-PCI records
let nonPCIRecords = ["table": "persons", "fields": [["gender": "MALE"]]]

// Send the Non-PCI records as additionalFields of InsertOptions (optional)
let options = Skyflow.CollectOptions(tokens: true, additionalFields: nonPCIRecords)

//Custom callback - implementation of Skyflow.callback
let insertCallback = InsertCallback() 
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
 
//Create Skyflow.Styles with individual Skyflow.Style variants
let baseStyle = Skyflow.Style(borderColor: UIColor.blue)
let baseTextStyle = Skyflow.Style(textColor: UIColor.black)
let completedStyle = Skyflow.Style(borderColor: UIColor.green)
val focusTextStyle = Skyflow.Style(textColor = UIColor.red)
let inputStyles = Skyflow.Styles(base: baseStyle, completed: completedStyle)
let labelStyles = Skyflow.Styles(base: baseTextStyle, focus: focusTextStyle)
let errorTextStyles = Skyflow.Styles(base: baseTextStyle)
 
// Create a CollectElementInput
let input = Skyflow.CollectElementInput(
    table: "cards",
    column: "cardNumber",
    type: Skyflow.ElementType.CARD_NUMBER,
    inputStyles: inputStyles,
    labelStyles: labelStyles,
    errorTextStyles: errorTextStyles,
    label: "card number",
    placeholder: "card number"
)

// Create option to make the element required
let requiredOption = Skyflow.CollectElementOptions(required: true) 

// Create a Collect Element from the Collect Container
let skyflowElement = container.create(input: input, options: requiredOption)
 
// Can interact with this object as a normal UIView Object and add to View
 
// Non-PCI records
let nonPCIRecords = ["table": "persons", "fields": [["gender": "MALE"]]]

// Send the Non-PCI records as additionalFields of CollectOptions (optional)
let collectOptions = Skyflow.CollectOptions(tokens: true, additionalFields: nonPCIRecords) 

 
//Implement a custom Skyflow.Callback to be called on Insertion success/failure
public class InsertCallback: Skyflow.Callback {
  public func onSuccess(_ responseBody: Any) {
      print(responseBody)
  }
   public func onFailure(_ error: Any) {
      print(error)
  }
}
 
// Initialize custom Skyflow.Callback
let insertCallback = InsertCallback()
 
// Call collect method on CollectContainer
container.collect(options: collectOptions, callback: insertCallback)

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
    },
    {
      "table": "persons",
      "fields": {
        "gender": "12f670af-6c7d-4837-83fb-30365fbc0b1e",
      }
    }
  ]
}

```

### Validations

Skyflow-iOS provides two types of validations on Collect Elements

#### 1. Default Validations:
Every Collect Element except of type `INPUT_FIELD` has a set of default validations listed below:
- `CARD_NUMBER`: Card number validation with checkSum algorithm(Luhn algorithm), available card lengths for defined card types
- `CARD_HOLDER_NAME`: Name should be 2 or more symbols, valid characters shold match pattern -  `^([a-zA-Z\\ \\,\\.\\-\\']{2,})$`
- `CVV`: Card CVV can have 3-4 digits
- `EXPIRATION_DATE`: Any date starting from current month. By default valid expiration date should be in short year format - `MM/YY`
- `PIN`: Can have 4-12 digits

#### 2. Custom Validations:
Custom validations can be added to any element which will be checked after the default validations have passed. The following Custom validation rules are currently supported:
- `RegexMatchRule`: You can use this rule to specify any Regular Expression to be matched with the text field value
- `LengthMatchRule`: You can use this rule to set the minimum and maximum permissible length of the textfield value
- `ElementValueMatchRule`: You can use this rule to match the value of one element with another

The Sample code below illustrates the usage of custom validations:

```swift
/*
  Reset PIN - A simple example that illustrates custom validations.
  The below code shows two input fields with custom validations, one to enter a PIN and the second to confirm the same PIN.
*/

var myRuleset = ValidationSet()
let digitsOnlyRule = RegexMatchRule(regex: "^\\d+$", error: "Only digits allowed") // this rule allows only 1 or more digits
let lengthRule = LengthMatchRule(minLength: 4, maxLength: 6, error: "Must be between 4 and 6 digits") // this rule allows input length between 4 and 6 characters

// for the PIN element
myRuleset.add(rule: digitsOnlyRule)
myRuleset.add(rule: lengthRule)

let PINinput = CollectElementInput(table: "table", column: "pin", inputStyles: styles, label: "PIN", placeholder: "****", type: .INPUT_FIELD, validations: myRuleset)
let PIN = container.create(input: PINinput)

// For confirm PIN element - shows error when the PINs don't match
let elementMatchRule = ElementMatchRule(element: PIN, error: "PINs don't match")

let confirmPINinput = CollectElementInput(table: "table", column: "pin", inputStyles: styles, label: "Confirm PIN", placeholder: "****", type: .INPUT_FIELD, validations: ValidationSet(rules: [digitsOnlyRule, lengthRule, elementMatchRule]))
let confirmPIN = container.create(input: confirmPINinput)

// mount elements on screen - errors will be shown if any of the validaitons fail
stackView.addArrangedSubview(PIN)
stackView.addArrangedSubview(confirmPIN)
```

### Event Listener on Collect Elements


Helps to communicate with skyflow elements / iframes by listening to an event

```swift
element.on(eventName: Skyflow.EventName) { state in
  //handle function
}
```

There are 4 events in `Skyflow.EventName`
- `CHANGE`  
  Change event is triggered when the Element's value changes.
- `READY`   
   Ready event is triggered when the Element is fully rendered
- `FOCUS`   
 Focus event is triggered when the Element gains focus
- `BLUR`    
  Blur event is triggered when the Element loses focus.
The handler ```(state: [String: Any]) -> Void``` is a callback function you provide, that will be called when the event is fired with the state object as shown below. 

```swift
let state = [
  "elementType": Skyflow.ElementType,
  "isEmpty": Bool ,
  "isFocused": Bool,
  "isValid": Bool,
  "value": String 
]
```
`Note:`
values of SkyflowElements will be returned in elementstate object only when `env` is  `DEV`,  else it is an empty string.

##### Sample code snippet for using listeners
```swift
//create skyflow client with loglevel:"DEBUG"
let config = Skyflow.Configuration(vaultID: VAULT_ID, vaultURL: VAULT_URL, tokenProvider: demoTokenProvider, options: Skyflow.Options(logLevel: Skyflow.LogLevel.DEBUG))

let skyflowClient = Skyflow.initialize(config)

let container = skyflowClient.container(type: Skyflow.ContainerType.COLLECT)
 
// Create a CollectElementInput
let cardNumberInput = Skyflow.CollectElementInput(
    table: "cards",
    column: "cardNumber",
    type: Skyflow.ElementType.CARD_NUMBER,
)

let cardNumber = container.create(input: cardNumberInput)

//subscribing to CHANGE event, which gets triggered when element changes
cardNumber.on(eventName: Skyflow.EventName.CHANGE) { state in
  // Your implementation when Change event occurs
  print(state)
}
```
##### Sample Element state object when `env` is `DEV`
```swift
[
   "elementType": Skyflow.ElementType.CARD_NUMBER,
   "isEmpty": false,
   "isFocused": true,
   "isValid": false,
   "value": "411"
]
```
##### Sample Element state object when `env` is `PROD`
```swift
[
   "elementType": Skyflow.ElementType.CARD_NUMBER,
   "isEmpty": false,
   "isFocused": true,
   "isValid": false,
   "value": ""
]
```

---
# Securely revealing data client-side
-  [**Retrieving data from the vault**](#retrieving-data-from-the-vault)
-  [**Using Skyflow Elements to reveal data**](#using-skyflow-elements-to-reveal-data)

## Retrieving data from the vault
For non-PCI use-cases, retrieving data from the vault and revealing it in the mobile can be done either using the SkyflowID's or tokens as described below

- ### Using Skyflow tokens
    For retrieving using tokens, use the `detokenize(records)` method. The records parameter takes a Dictionary object that contains `records` to be fetched as shown below.
    ```swift
    [
      "records":[
        [
          "token": "string"     // token for the record to be fetched
        ]
      ]
    ]
   ```
   
  An example of a detokenize call:
  ```swift
  let getCallback = GetCallback()   //Custom callback - implementation of Skyflow.Callback

  let records = ["records": [["token": "45012507-f72b-4f5c-9bf9-86b133bae719"]]] as [String: Any]

  skyflowClient.detokenize(records: records, callback: getCallback)
  ```
  The sample response:
  ```json
  {
    "records": [
      {
        "token": "131e70dc-6f76-4319-bdd3-96281e051051",
        "value": "1990-01-01"
      }
    ]
  }
  ```

- ### Using Skyflow ID's
    For retrieving using SkyflowID's, use the `getById(records)` method. The records parameter takes a Dictionary object that contains `records` to be fetched as shown below.
    ```swift
    [
      "records":[
        [
          "ids": ArrayList<String>(),           // Array of SkyflowID's of the records to be fetched
          "table": "string",                    // name of table holding the above skyflow_id's
          "redaction": Skyflow.RedactionType    //redaction to be applied to retrieved data
        ]
      ]
    ]
    ```

  There are 4 accepted values in Skyflow.RedactionTypes:  
  - `PLAIN_TEXT`
  - `MASKED`
  - `REDACTED`
  - `DEFAULT`  
  
  An example of getById call:
  ```swift
  let getCallback = GetCallback() //Custom callback - implementation of Skyflow.Callback

  let skyflowIDs = ["f8d8a622-b557-4c6b-a12c-c5ebe0b0bfd9", "da26de53-95d5-4bdb-99db-8d8c66a35ff9"]
  let record = ["ids": skyflowIDs, "table": "cards", "redaction": Redaction.PLAIN_TEXT] as [String : Any]

  let invalidID = ["invalid skyflow ID"]
  let badRecord = ["ids": invalidID, "table": "cards", "redaction": Redaction.PLAIN_TEXT] as [String : Any]

  let records = ["records": [record, badRecord]]

  skyflowClient.getById(records: records, callback: getCallBack)
  ```

  The sample response:
  ```json
  {
    "records": [
        {
            "fields": {
                "card_number": "4111111111111111",
                "cvv": "127",
                "expiry_date": "11/35",
                "fullname": "myname",
                "skyflow_id": "f8d8a622-b557-4c6b-a12c-c5ebe0b0bfd9"
            },
            "table": "cards"
        },
        {
            "fields": {
                "card_number": "4111111111111111",
                "cvv": "317",
                "expiry_date": "10/23",
                "fullname": "sam",
                "skyflow_id": "da26de53-95d5-4bdb-99db-8d8c66a35ff9"
            },
            "table": "cards"
        }
    ],
    "errors": [
        {
            "error": {
                "code": "404",
                "description": "No Records Found"
            },
            "skyflow_ids": ["invalid skyflow id"]
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
    token: String,                     //optional, token of the data being revealed 
    inputStyles: Skyflow.Styles(),       //optional, styles to be applied to the element
    labelStyles: Skyflow.Styles(),       //optional, styles to be applied to the label of the reveal element
    errorTextStyles: Skyflow.Styles(),   //optional styles that will be applied to the errorText of the reveal element
    label: "cardNumber"                  //optional, label for the element,
    altText: "XXXX XXXX XXXX XXXX"       //optional, string that is shown before reveal, will show token if altText is not provided
```
`Note`: 
- `token` is optional only if it is being used in invokeConnection()

The `inputStyles` parameter accepts a styles object as described in the [previous section](#step-2-create-a-collect-element) for collecting data but the only state available for a reveal element is the base state. 

The `labelStyles` and `errorTextStyles` fields accept the above mentioned `Skyflow.Styles` object as described in the [previous section](#step-2-create-a-collect-element), the only state available for a reveal element is the base state.

The `inputStyles`, `labelStyles` and  `errorTextStyles` parameters accepts a styles object as described in the [previous section](#step-2-create-a-collect-element) for collecting data but only a single variant is available i.e. base. 

An example of a inputStyles object:

```swift
let inputStyles = Skyflow.Styles(base: Skyflow.Style(borderColor = Color.BLUE))
```

An example of a labelStyles object:

```swift
let labelStyles = Skyflow.Styles(base: Skyflow.Style(font: 12))
```

An example of a errorTextStyles object:

```swift
let labelStyles = Skyflow.Styles(base: Skyflow.Style(textColor: UIColor.red))
```

Once you've defined a `Skyflow.RevealElementInput` object, you can use the `create()` method of the container to create the Element as shown below:

```swift
let element = container.create(input: revealElementInput)
```

### Step 3: Mount Elements to the Screen

Elements used for revealing data are mounted to the screen the same way as Elements used for collecting data. Refer to Step 3 of the [section above](#step-3-mount-elements-to-the-screen).

### Step 4: Reveal data
When the sensitive data is ready to be retrieved and revealed, call the `reveal()` method on the container as shown below:
```swift
let revealCallback = RevealCallback()  // Custom callback - implementation of Skyflow.Callback
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
val baseTextStyle = Skyflow.Style(textColor: UIColor.BLACK)
val inputStyles = Skyflow.Styles(base: baseStyle)
val labelStyles = Skyflow.Styles(base: baseTextStyle)
val errorTextStyles = Skyflow.Styles(base: baseTextStyle)
 
//Create Reveal Elements
let cardNumberInput = Skyflow.RevealElementInput(
    token: "b63ec4e0-bbad-4e43-96e6-6bd50f483f75",
    inputStyles: inputStyles,
    labelStyles: labelStyles,
    errorTextStyles: errorTextStyles,
    label: "cardnumber",
    altText: "XXXX XXXX XXXX XXXX"
)

let cardNumberElement = container.create(input: cardNumberInput)

let cvvInput = Skyflow.RevealElementInput(
    token: "89024714-6a26-4256-b9d4-55ad69aa4047",
    inputStyles: inputStyles,
    labelStyles: labelStyles,
    errorTextStyles: errorTextStyles,
    label: "cvv",
    altText: "XXX"
)
let cvvElement = container.create(input: cvvInput)

//Can interact with these objects as a normal UIView Object and add to View
 
//Implement a custom Skyflow.Callback to be called on Reveal success/failure
public class RevealCallback: Skyflow.Callback {
  public func onSuccess(_ responseBody: Any) {
      print(responseBody)
  }
   public func onFailure(_ error: Any) {
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


# Securely invoking connection client-side
Using Skyflow Connections, end-user applications can integrate checkout/card issuance flow without any of their apps/systems touching the PCI compliant fields like cvv, card number. To invoke a connection, use the `invokeConnection(config: Skyflow.ConnectionConfig, callback: Skyflow.Callback)` method of the Skyflow client.
```swift
let connectionConfig = Skyflow.ConnectionConfig(
  connectionURL: String, // connection url received when creating a skyflow connection integration
  methodName: Skyflow.RequestMethod,
  pathParams: [String: Any],	// optional
  queryParams: [String: Any],	// optional
  requestHeader: [String: String], // optional
  requestBody: [String: Any],	// optional
  responseBody: [String: Any]	// optional
)
skyflowClient.invokeConnection(config: connectionConfig, callback: callback);
```
`methodName` supports the following methods:
- GET
- POST
- PUT
- PATCH
- DELETE

**pathParams, queryParams, requestHeader, requestBody** are the JSON objects represented as dictionaries that will be sent through the connection integration url.
The values in the above parameters can contain collect elements, reveal elements or actual values. When elements are provided inplace of values, they get replaced with the value entered in the collect elements or value present in the reveal elements

**responseBody**:  
It is a JSON object represented as a dictionary that specifies where to render the response in the UI. The values in the responseBody can contain collect elements or reveal elements. 

Sample use-cases on using invokeConnection():
###  Sample use-case 1:
Merchant acceptance - customers should be able to complete payment checkout without cvv touching their application. This means that the merchant should be able to receive a CVV and process a payment without exposing their front-end to any PCI data
```swift
// step 1
let config = Skyflow.Configuration(vaultID: <VAULT_ID>, vaultURL: <VAULT_URL>, tokenProvider: demoTokenProvider)

let skyflowClient = Skyflow.initialize(config)

// step 2
let collectContainer = skyflowClient.container(type: Skyflow.ContainerType.COLLECT)

// step 3
let cardNumberInput = Skyflow.CollectElementInput(
    type: Skyflow.ElementType.CARD_NUMBER,
)

let cardNumberElement = collectContainer.create(input: cardNumberInput)

let cvvElementInput = Skyflow.CollectElementInput(
    type: Skyflow.ElementType.CVV,
)

let cvvElement = collectContainer.create(input: cvvInput)

//Can interact with these objects as a normal UIView Object and add to View

// step 4
let connectionConfig = Skyflow.ConnectionConfig( 
  connectionURL: "https://area51.gateway.skyflow.com/v1/gateway/inboundRoutes/abc-1213/v2/pay",
  methodName: Skyflow.RequestMethod.POST,
  requestBody: [
   "card_number": cardNumberElement, //it can be skyflow element(collect or reveal) or actual value
   "cvv": cvvElement,  
  ]
)

//Implement a custom Skyflow.Callback to be called on Reveal success/failure
public class InvokeConnectionCallback: Skyflow.Callback {
  public func onSuccess(_ responseBody: Any) {
      print(responseBody)
  }
   public func onFailure(_ error: Any) {
      print(error)
  }
}
 
//Initialize custom Skyflow.Callback
let invokeConnectionCallback = InvokeConnectionCallback()

skyflowClient.invokeConnection(config: connectionConfig, callback: invokeConnectionCallback)
```
Sample Response:
```javascript
{
   "receivedTimestamp": "2019-05-29 21:49:56.625",
   "processingTimeinMs": 116
}
```
In the above example,  CVV is being collected from the user input at the time of checkout and not stored anywhere in the vault

`Note:`  
- card_number can be either container element or plain text value (tokens or actual value)
- `table` and `column` names are not required for creating collect element, if it is used for invokeConnection method, since they will not be stored in the vault
 ### Sample use-case 2:
 
 Card issuance -  customers want to issue cards from card issuer service and should generate the CVV dynamically without increasing their PCI scope.
```swift
// step 1
let config = Skyflow.Configuration(vaultID: <VAULT_ID>, vaultURL: <VAULT_URL>, tokenProvider: demoTokenProvider)

let skyflowClient = Skyflow.initialize(config)

// step 2
let revealContainer = skyflowClient.container(type: Skyflow.ContainerType.REVEAL)
let collectContainer = skyflowClient.container(type: Skyflow.ContainerType.COLLECT)

// step 3
let cvvInput = RevealElementInput(
  altText: "CVV"
)

let cvvElement = revealContainer.create(input: cvvElementInput)

let expiryDateInput = CollectElementInput(
  type: skyflow.ElementType.EXPIRATION_DATE
)

let expiryDateElement = collectContainer.create(input: expiryDateInput)

//Can interact with these objects as a normal UIView Object and add to View

//step 4
let connectionConfig = ConnectionConfig(
  connectionURL: "https://area51.gateway.skyflow.com/v1/gateway/inboundRoutes/abc-1213/cards/{card_number}/cvv2generation",
  methodName: Skyflow.RequestMethod.POST,
  pathParams: [
     "card_number": "0905-8672-0773-0628"	//it can be skyflow element(collect/reveal) or token or actual value
  ],
  requestBody: [
    "expirationDate": expiryDateElement //it can be skyflow element(collect/reveal) or token or actual value
 ],
 responseBody: [
     "resource": [
         "cvv2": cvvElement   // pass the element where the cvv response from the connection will be mounted
      ]
    ]  
)

//Implement a custom Skyflow.Callback to be called on Reveal success/failure
public class InvokeConnectionCallback: Skyflow.Callback {
  public func onSuccess(_ responseBody: Any) {
      print(responseBody)
  }
   public func onFailure(_ error: Any) {
      print(error)
  }
}
 
//Initialize custom Skyflow.Callback
let invokeConnectionCallback = InvokeConnectionCallback()

skyflowClient.invokeConnection(config: connectionConfig, callback: invokeConnectionCallback)
```
Sample Response:
```javascript
{
   "receivedTimestamp": "2019-05-29 21:49:56.625",
   "processingTimeinMs": 116
}
```
`Note`:
- `token` is optional for creating reveal element, if it is used for invokeConnection
- responseBody contains collect or reveal elements to render the response from the connection on UI 
