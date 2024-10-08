# skyflow-iOS
---
Skyflow’s iOS SDK can be used to securely collect, tokenize, and display sensitive data in the mobile without exposing your front-end infrastructure to sensitive data. 
 
[![CI](https://img.shields.io/static/v1?label=CI&message=passing&color=green?style=plastic&logo=github)](https://github.com/skyflowapi/skyflow-ios/actions)
[![GitHub release](https://img.shields.io/github/v/release/skyflowapi/skyflow-ios.svg)](https://github.com/skyflowapi/skyflow-ios/releases)
[![License](https://img.shields.io/github/license/skyflowapi/skyflow-ios)](https://github.com/skyflowapi/skyflow-ios/blob/main/LICENSE)
 
# Table of Contents
- [Installation](#installation)
    - [Requirements](#requirements)
    - [Configuration](#configuration)
- [Initializing Skyflow-iOS](#initializing-skyflow-ios)
- [Securely collecting data client-side](#securely-collecting-data-client-side)
- [Securely collecting data client-side using Composable Elements](#securely-collecting-data-client-side-using-composable-elements)
- [Securely revealing data client-side](#securely-revealing-data-client-side)
 
# Installation
 
## Requirements
- iOS 15.0 and above
 
## Configuration
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
public class DemoTokenProvider: Skyflow.TokenProvider {
    public func getBearerToken(_ apiCallback: Skyflow.Callback) {
        if let url = URL(string: <YOUR_TOKEN_ENDPOINT>) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) {data, _, error in
                if error != nil {
                    print(error!)
                    return
                }
                if let safeData = data {
                    do {
                        let x = try JSONSerialization.jsonObject(with: safeData, options: []) as? [String: String]
                        if let accessToken = x?["accessToken"] {
                            apiCallback.onSuccess(accessToken)
                        }
                    } catch {
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
-  [**Inserting data into the vault**](#insert-data-into-the-vault)
-  [**Using Skyflow Elements to collect data**](#using-skyflow-elements-to-collect-data)
-  [**Using validations on Collect Elements**](#validations)
-  [**Event Listener on Collect Elements**](#event-listener-on-collect-elements)
-  [**UI Error for Collect Elements**](#ui-error-for-collect-elements)
-  [**Set and Clear value for Collect Elements (DEV ENV ONLY)**](#set-and-clear-value-for-collect-elements-dev-env-only)
 
## Insert data into the vault
 
 To insert data into your vault, use the `skyflowClient.insert()` method. 
 ```swift
 insert(records: [String: Any], options: InsertOptions?= InsertOptions() , callback: Skyflow.Callback) 
 ```
 The `insert()` method requires a records parameter. 
 The `records` parameter takes an array of records to insert into the vault.
 
#### Insert call example
 ```swift
 let insertCallback = InsertCallback()     //A Custom callback using Skyflow.Callback
 skyflowClient.insert(
    records: [
        "records": [
            [
                "table": "cards",
                "fields": [
                    "cardNumber": "41111111111",
                    "cvv": "123",
                ]
            ]
        ]
    ],
    callback: insertCallback
)
```
Skyflow returns tokens for the record you just inserted.
```json
{
    "records": [ {
        "table": "cards",
        "fields": {
            "cardNumber": "f37186-e7e2-466f-91e5-48e12c2bcbc1",
            "cvv": "1989cb56-63da-4482-a2df-1f74cd0dd1a5"
        }
    }]
}
```
 
 The `options` parameter takes a Skyflow.InsertOptions object.
 
 InsertOptions includes a `tokens` boolean that controls whether you receive tokens after inserting a record into the vault.

InsertOptions also supports the **upsert** feature, that lets you conditionally insert or update an existing record by specifying the unique column to use as the unique value.

For example, if you specify the ‘customer_id’ column to use for upsert, and the same customer_id  already exists, the existing record will update. If the customer_id doesn't exist, the vault creates a new record.

#### Insert call example
```swift
let records = [
    "records" : [
        [
            "table": "customers",  //The table where you are inserting the record.
            "fields": [                         
                "name" : "Francis",
                "customer_id" : "12345"
            ]
        ]
    ]
]

let upsertOptions = [["table": "customers", "column": "customer_id"]] as [[String : Any]]
let insertOptions = Skyflow.InsertOptions(tokens: false, upsert: upsertOptions)
let insertCallback = InsertCallback()  //Custom callback - implementation of Skyflow.Callback

skyflowClient.insert(records: records, options: insertOptions, callback: insertCallback)
```

## Using Skyflow Elements to collect data
 
**Skyflow Elements** provide developers with pre-built form elements to securely collect sensitive data client-side. This reduces your PCI compliance scope by not exposing your front-end application to sensitive data. Follow the steps below to securely collect data with Skyflow Elements in your application.
 
### Step 1: Create a container
 
First create a **container** for the form elements using the ```skyflowClient.container(type: Skyflow.ContainerType)``` method as show below
 
```swift
let container = skyflowClient.container(type: Skyflow.ContainerType.COLLECT)
```
 
### Step 2: Create a collect Element
To create a collect Element, we must first construct a Skyflow.CollectElementInput object defined as shown below:
 
```swift
let collectElementInput = Skyflow.CollectElementInput(
    table: String,                  // optional, the table this data belongs to
    column: String,                 // optional, the column into which this data should be inserted
    inputStyles: Skyflow.Styles,     // optional styles that should be applied to the form element
    labelStyles: Skyflow.Styles,     // optional styles that will be applied to the label of the collect element
    errorTextStyles: Skyflow.Styles, // optional styles that will be applied to the errorText of the collect element
    label: String,                   // optional label for the form element
    placeholder: String,             // optional placeholder for the form element
    altText: String,                 // (DEPRECATED) optional that acts as an initial value for the collect element
    validations: ValidationSet,      // optional set of validations for the input element
    type: Skyflow.ElementType,       // Skyflow.ElementType enum
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
     borderColor: UIColor,                        // optional
     cornerRadius: CGFloat,                       // optional
     padding: UIEdgeInsets,                       // optional
     borderWidth: CGFloat,                        // optional
     font: UIFont,                                // optional
     textAlignment: NSTextAlignment,              // optional
     textColor: UIColor,                          // optional
     boxShadow: CALayer,                         // optional
     backgroundColor: UIColor,                    // optional
     minWidth: CGFloat,                           // optional
     maxWidth: CGFloat,                           // optional
     minHeight: CGFloat,                          // optional
     maxHeight: CGFloat,                          // optional
     cursorColor: UIColor,                        // optional
     width: CGFloat,                              // optional
     height: CGFloat,                             // optional
     placeholderColor: UIColor,                   // optional
     cardIconAlignment: CardIconAlignment         // optional, Skyflow.CardIconAlignment enum, default is .left
)
```
 
An example Skyflow.Styles object
```swift
let styles = Skyflow.Styles(
    base: style,                    // optional
    complete: style,                // optional
    empty: style,                   // optional
    focus: style,                   // optional
    invalid: style,                 // optional
    requiredAsterisk: style        // optional 
)
```
 
The `labelStyles` and `errorTextStyles` fields accept the above mentioned `Skyflow.Styles` object which are applied to the `label` and `errorText` text views respectively.
 
The states that are available for `labelStyles` are `base` and `focus`.

`requiredAsterisk`: Styles applied for the Asterisk symbol in the label. Defaults to red.

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
- `EXPIRATION_YEAR`
- `EXPIRATION_MONTH`
 
 
The `INPUT_FIELD` type is a custom UI element without any built-in validations. See the section on [validations](#validations) for more information on validations.
 
Along with `CollectElementInput`, you can define other options in the `CollectElementOptions` object which is described below.
 
```swift
Skyflow.CollectElementOptions(
  required: Boolean,               // Indicates whether the field is marked as required. Defaults to 'false'
  enableCardIcon: Boolean,         // Indicates whether card icon should be enabled (only for CARD_NUMBER inputs)
  format: String,                  // Format for the element 
  translation: [Character: String] // Indicates the allowed data type value for format.
  enableCopy: Boolean,             // Indicates whether to enable the copy icon in collect elements to copy text to clipboard. Defaults to 'false'
  cardMetaData: [String: [Skyflow.CardType]]      // Optional, metadata to control card number element behavior. (only applicable for CARD_NUMBER ElementType).
)
```
    
- `required`: Indicates whether the field is marked as required or not. Default is `false`.
- `enableCardIcon`: Indicates whether the icon is visible for the CARD_NUMBER element. Default is `true`.
- `format`:  A string value that indicates the format pattern applicable to the element type. Only applicable to EXPIRATION_DATE, CARD_NUMBER, EXPIRATION_YEAR, and INPUT_FIELD elements.
   For INPUT_FIELD elements,
     -  the length of `format` determines the expected length of the user input.
     - if `translation` isn't specified, the `format` value is considered a string literal.
- `translation`: A dictionary of key/value pairs, where the key is a character that appears in `format` and the value is a regex pattern of acceptable inputs for that character. Each key can only appear once. Only applicable for INPUT_FIELD elements.
- `enableCopy`: Indicates whether to enable the copy icon in collect elements to copy text to clipboard.
- `cardMetaData`: An object of metadata keys to control card number element behavior. It supports an optional key called `scheme`, which accepts an array of Skyflow-supported card types and determines which brands display in the card number element's card brand choice dropdown. `Skyflow.CardType` is an enum with all Skyflow-supported card schemes.

```swift
import Skyflow

const cardMetaData = [ "scheme": [Skyflow.CardType]] // Optional, array of skyflow supported card types.
```

#### Supported card types by Skyflow.CardType :
- `VISA`
- `MASTERCARD`
- `AMEX`
- `DINERS_CLUB`
- `DISCOVER`
- `JCB`
- `MAESTRO`
- `UNIONPAY`
- `HIPERCARD`
- `CARTES_BANCAIRES`
  
Update cardMetaData:
```swift
cardNumberElement.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [Skyflow.CardType.CARTES_BANCAIRES, Skyflow.CardType.MASTERCARD]]))
```

Accepted values by element type:

| Element type | `format`and `translation` values  | Examples |
| -------------|  -------------------------------  | -------- |
| EXPIRATION_DATE  | <ul> <li>`format`</li><ul><li>`mm/yy`(default)</li><li>`mm/yyyy`</li> <li>`yy/mm`</li> <li> `yyyy/mm`</li></ul> |  <ul><li>12/27</li><li>12/2027</li> <li>27/12</li> <li> 2027/12</li></ul></ul>   | 
| EXPIRATION_YEAR   | <ul> <li>`format`</li><ul><li>`yyyy` (default)</li><li>`yy`</li> </ul> </ul> | <ul><li>27</li><li>2027</li> </ul> |
| CARD_NUMBER | <ul> <li>`format`</li><ul><li> `XXXX XXXX XXXX XXXX` (default)</li><li>`XXXX-XXXX-XXXX-XXXX`</li> </ul> </ul> | <ul><li>1234 5678 9012 3456</li><li>1234-5678-9012-3456</li> </ul>  |
| INPUT_FIELD |  <ul><li>`format`: A string that matches the desired output, with placeholder characters of your choice.</li><li>`translation`: A dictionary of key/value pairs. Defaults to `[ "X": "[0-9]"]`</li> </ul> | With a `format` of `+91 XXXX-XX-XXXX` and a `translation` of `[ "X": "[0-9]"]`, user input of "1234121234" displays as "+91 1234-12-1234". |

Collect Element Options examples for INPUT_FIELD
Example 1
```swift
Skyflow.CollectElementOptions(
  required: true, 
  enableCardIcon: true,
  format:   "+91 XXXX-XX-XXXX",
  translation: [ "X": "[0-9]"] 
)
```
User input: "1234121234"

Value displayed in INPUT_FIELD: "+91 1234-12-1234"    

Example 2
```swift
Skyflow.CollectElementOptions(
  required: true, 
  enableCardIcon: true,
  format:   "AY XX-XXX-XXXX",
  translation: [ "X": "[0-9]", "Y": "[A-Z]"] 
)
```
User input: "B1234121234"

Value displayed in INPUT_FIELD: "AB 12-341-2123"

Once the `Skyflow.CollectElementInput` and `Skyflow.CollectElementOptions` objects are defined, add to the container using the ```create(input: CollectElementInput, options: CollectElementOptions)``` method as shown below. The `input` param takes a `Skyflow.CollectElementInput` object as defined above and the `options` parameter takes an `Skyflow.CollectElementOptions` object as described below:
 
```swift
let collectElementInput = Skyflow.CollectElementInput(
    table: String,                  // the table this data belongs to
    column: String,                 // the column into which this data should be inserted
    inputStyles: Skyflow.Styles,     // optional styles that should be applied to the form element
    labelStyles: Skyflow.Styles,     // optional styles that will be applied to the label of the collect element
    errorTextStyles: Skyflow.Styles, // optional styles that will be applied to the errorText of the collect element
    label: String,                   // optional label for the form element
    placeholder: String,             // optional placeholder for the form element
    altText: String,                 // (DEPRECATED) optional that acts as an initial value for the collect element
    validations: ValidationSet,      // optional set of validations for the input element
    type: Skyflow.ElementType,       // Skyflow.ElementType enum
)

let collectElementOptions = Skyflow.CollectElementOptions(
    required: false,      // indicates whether the field is marked as required. Defaults to 'false',
    enableCardIcon: true, // indicates whether card icon should be enabled (only for CARD_NUMBER inputs)
    format: "mm/yy"       // format for the element,
    enableCopy: true,     // indicates whether to enable the copy icon in collect elements to copy text to clipboard. Defaults to 'false'
)

let element = container?.create(input: collectElementInput, options: collectElementOptions)
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
When you submit the form, call the `collect(options: Skyflow.CollectOptions? = nil, callback: Skyflow.Callback)` method on the container object. The options parameter takes a `Skyflow.CollectOptions` object as shown below:
```swift
// Non-PCI records
let nonPCIRecords = ["table": "persons", "fields": [["gender": "MALE"]]]
// Upsert
let upsertOptions = [["table": "cards", "column": "cardNumber"]] as [[String : Any]]
// Send the non-PCI records as additionalFields of InsertOptions (optional) and apply upsert using `upsert` field of InsertOptions (optional)

let options = Skyflow.CollectOptions(tokens: true, additionalFields: nonPCIRecords)
 
//Custom callback - implementation of Skyflow.callback
let insertCallback = InsertCallback() 
container?.collect(callback: insertCallback, options: options)

```
### Collect data with Skyflow Elements
 
#### Collect call example:
```swift

//Initialize skyflow configuration.
let config = Skyflow.Configuration(vaultID: VAULT_ID, vaultURL: VAULT_URL, tokenProvider: demoTokenProvider)
 
//Initialize skyflow client.
let skyflowClient = Skyflow.initialize(config)
 
//Create a CollectContainer.
let container = skyflowClient.container(type: Skyflow.ContainerType.COLLECT)
 
//Create Skyflow.Styles with individual Skyflow.Style variants.
let baseStyle = Skyflow.Style(borderColor: UIColor.blue)
let baseTextStyle = Skyflow.Style(textColor: UIColor.black)
let completeStyle = Skyflow.Style(borderColor: UIColor.green)
let focusTextStyle = Skyflow.Style(textColor: UIColor.red)
let inputStyles = Skyflow.Styles(base: baseStyle, complete: completeStyle)
let labelStyles = Skyflow.Styles(base: baseTextStyle, focus: focusTextStyle)
let errorTextStyles = Skyflow.Styles(base: baseTextStyle)

let iconStyles = Skyflow.Styles(base: Style(cardIconAlignment: .left))
 
// Create a CollectElementInput.
let input = Skyflow.CollectElementInput(
    table: "cards",
    column: "cardNumber",
    inputStyles: inputStyles,
    labelStyles: labelStyles,
    errorTextStyles: errorTextStyles,
    iconStyles: iconStyles,
    label: "card number",
    placeholder: "card number",
    type: Skyflow.ElementType.CARD_NUMBER
)
 
// Create an option to require the element.
let requiredOption = Skyflow.CollectElementOptions(required: true, enableCopy: true) 
 
// Create a Collect Element from the Collect Container.
let skyflowElement = container?.create(input: input, options: requiredOption)
 
// Can interact with this object as a normal UIView Object and add to View
 
// Non-PCI records
let nonPCIRecords = ["table": "persons", "fields": [["gender": "MALE"]]]
 
 //Upsert options
 let upsertOptions = [["table": "cards", "column": "cardNumber"]] as [[String : Any]]
 
// Send the Non-PCI records as additionalFields of CollectOptions (optional) and apply upsert using optional field `upsert` of CollectOptions.
let collectOptions = Skyflow.CollectOptions(tokens: true, additionalFields: nonPCIRecords, upsert: upsertOptions) 
 
 
//Implement a custom Skyflow.Callback to call on Insertion success/failure.
public class InsertCallback: Skyflow.Callback {
  public func onSuccess(_ responseBody: Any) {
      print(responseBody)
  }
   public func onFailure(_ error: Any) {
      print(error)
  }
}
 

// Initialize custom Skyflow.Callback.
let insertCallback = InsertCallback()
 
// Call collect method on CollectContainer.
container?.collect(callback: insertCallback, options: collectOptions)
```
#### Skyflow returns tokens for the record you just inserted:
```
{
    "records": [ {
        "table": "cards",
        "fields": {
            "cardNumber": "f3907186-e7e2-466f-91e5-48e12c2bcbc1"
        }
    }, {
        "table": "persons",
        "fields": {
            "gender": "12f670af-6c7d-4837-83fb-30365fbc0b1e",
        }
    }]
}
```
 
### Validations
 
Skyflow-iOS provides two types of validations on Collect Elements
 
#### 1. Default Validations:
Every Collect Element except of type `INPUT_FIELD` has a set of default validations listed below:
- `CARD_NUMBER`: Card number validation with checkSum algorithm(Luhn algorithm), available card lengths for defined card types
- `CARD_HOLDER_NAME`: Name should be 2 or more symbols, valid characters should match pattern -  `^([a-zA-Z\\ \\,\\.\\-\\']{2,})$`
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
 Reset Password - A simple example that illustrates custom validations.
 The below code shows two input fields with custom validations,
 one to enter a password and the second to confirm the same password.
 */

var myRuleset = ValidationSet()
let strongPasswordRule = RegexMatchRule(
    regex: "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]*$",
    error: "At least one letter and one number"
) // This rule enforces a strong password

let lengthRule = LengthMatchRule(
    minLength: 8,
    maxLength: 16,
    error: "Must be between 8 and 16 digits"
) // this rule allows input length between 8 and 16 characters

// for the Password element
myRuleset.add(rule: strongPasswordRule)
myRuleset.add(rule: lengthRule)

let collectElementOptions = CollectElementOptions(required: true)

let passwordInput = CollectElementInput(
    inputStyles: styles,
    label: "password",
    placeholder: "********",
    type: .INPUT_FIELD,
    validations: myRuleset
)
let password = container?.create(input: passwordInput, options: collectElementOptions)

// For confirm password element - shows error when the passwords don't match
let elementValueMatchRule = ElementValueMatchRule(element: password!, error: "passwords don't match")
let confirmPasswordInput = CollectElementInput(
    inputStyles: styles,
    label: "Confirm password",
    placeholder: "********",
    type: .INPUT_FIELD,
    validations: ValidationSet(rules: [strongPasswordRule, lengthRule, elementValueMatchRule])
)
let confirmPassword = container?.create(input: confirmPasswordInput, options: collectElementOptions)

// mount elements on screen - errors will be shown if any of the validaitons fail
stackView.addArrangedSubview(password!)
stackView.addArrangedSubview(confirmPassword!)
```
 
### Event Listener on Collect Elements
 
 
Helps to communicate with skyflow elements by listening to an event
 
```swift
element!.on(eventName: Skyflow.EventName) { _ in
    // handle function
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
    "value": String,
    "selectedCardScheme": String // only for CARD_NUMBER element type
]
```
`Note:`
- values of SkyflowElements will be returned in element state object only when `env` is `DEV`, else it is empty string i.e, '', but in case of CARD_NUMBER type element when the `env` is `PROD` for all the card types except AMEX, it will return first eight digits, for AMEX it will return first six digits and rest all digits in masked format.
- `selectedCardScheme` is only populated for the `CARD_NUMBER` element state when a user chooses a card brand. By default, `selectedCardScheme` is an empty string.
 
##### Sample code snippet for using listeners
```swift
// create skyflow client with loglevel:"DEBUG"
let config = Skyflow.Configuration(
    vaultID: VAULT_ID,
    vaultURL: VAULT_URL,
    tokenProvider: demoTokenProvider,
    options: Skyflow.Options(logLevel: Skyflow.LogLevel.DEBUG)
)

let skyflowClient = Skyflow.initialize(config)

let container = skyflowClient.container(type: Skyflow.ContainerType.COLLECT)

// Create a CollectElementInput
let cardNumberInput = Skyflow.CollectElementInput(
    table: "cards",
    column: "cardNumber",
    type: Skyflow.ElementType.CARD_NUMBER,
    )
let cardHolderNameInput = Skyflow.CollectElementInput(
    table: "cards",
    column: "cardHolderName",
    type: Skyflow.ElementType.CARDHOLDER_NAME,
    )    

let cardNumber = container?.create(input: cardNumberInput)
let cardHolderName = container?.create(input: cardHolderNameInput)


// subscribing to CHANGE event, which gets triggered when element changes
cardNumber.on(eventName: Skyflow.EventName.CHANGE) { state in
    // Your implementation when Change event occurs
    print(state)
}

cardHolderName.on(eventName: Skyflow.EventName.CHANGE) { state in
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
    "isValid": true,
    "value": "4111111111111111"
]
[
    "elementType": Skyflow.ElementType.CARDHOLDER_NAME,
    "isEmpty": false,
    "isFocused": true,
    "isValid": true,
    "value": "John"
]

```
##### Sample Element state object when `env` is `PROD`
```swift
[
    "elementType": Skyflow.ElementType.CARD_NUMBER,
    "isEmpty": false,
    "isFocused": true,
    "isValid": true,
    "value": "41111111XXXXXXXX"
]
[
    "elementType": Skyflow.ElementType.CARDHOLDER_NAME,
    "isEmpty": false,
    "isFocused": true,
    "isValid": true,
    "value": ""
]
```
### UI Error for Collect Elements
 
Helps to display custom error messages on the Skyflow Elements through the methods `setError` and `resetError` on the elements.
 
`setError(error: String)` method is used to set the error text for the element, when this method is trigerred, all the current errors present on the element will be overridden with the custom error message passed. This error will be displayed on the element until `resetError()` is trigerred on the same element.
 
`resetError()` method is used to clear the custom error message that is set using `setError`.
 
##### Sample code snippet for setError and resetError
 
```swift
// Create skyflow client with loglevel:"DEBUG"
let config = Skyflow.Configuration(
    vaultID: VAULT_ID,
    vaultURL: VAULT_URL,
    tokenProvider: demoTokenProvider,
    options: Skyflow.Options(logLevel: Skyflow.LogLevel.DEBUG)
)

let skyflowClient = Skyflow.initialize(config)

let container = skyflowClient.container(type: Skyflow.ContainerType.COLLECT)

// Create a CollectElementInput
let cardNumberInput = Skyflow.CollectElementInput(
    table: "cards",
    column: "cardNumber",
    type: Skyflow.ElementType.CARD_NUMBER
)

let cardNumber = container.create(input: cardNumberInput)

// Set custom error
cardNumber.setError("custom error")

// Reset custom error
cardNumber.resetError()
```
 
### Set and Clear value for Collect Elements (DEV ENV ONLY)
 
`setValue(value: String)` method is used to set the value of the element. This method will override any previous value present in the element.
 
`clearValue()` method is used to reset the value of the element.
 
`Note:` This methods are only available in DEV env for testing/developmental purposes and MUST NOT be used in PROD env.
 
##### Sample code snippet for setValue and clearValue
 
```swift
// Create skyflow client with env DEV
let config = Skyflow.Configuration(
    vaultID: VAULT_ID,
    vaultURL: VAULT_URL,
    tokenProvider: demoTokenProvider,
    options: Skyflow.Options(env: Skyflow.Env.DEV)
)

let skyflowClient = Skyflow.initialize(config)

let container = skyflowClient.container(type: Skyflow.ContainerType.COLLECT)

// Create a CollectElementInput
let cardNumberInput = Skyflow.CollectElementInput(
    table: "cards",
    column: "cardNumber",
    type: Skyflow.ElementType.CARD_NUMBER
)

let cardNumber = container.create(input: cardNumberInput)

// Set a value programatically
cardNumber.setValue("4111111111111111")

// Clear the value
cardNumber.clearValue()
```
 
# Securely collecting data client-side using Composable Elements

Composable Elements combine multiple Skyflow Elements in a single row. The following steps create a composable element and securely collect data through it.

## Step 1: Create a composable container

First create a **container** for the form elements using the ```skyflowClient.container(type: Skyflow.ContainerType)``` method as show below

```swift
let container = skyflowClient.container(type: Skyflow.ContainerType.COMPOSABLE,  options: ContainerOptions)
```

The container requires an options object that contains the following keys:

- `layout`: An array that indicates the number of rows in the container and the number of elements in each row. The index value of the array defines the number of rows, and each value in the array represents the number of elements in that row, in order.

    For example: `[2,1]` means the container has two rows, with two elements in the first row and one element in the second row.

    `Note`: The sum of values in the layout array should be equal to the number of elements created

- `styles`: styles to apply to each composable row.

- `errorTextStyles`: styles to apply if an error is encountered.

```swift
var containerOptions = ContainerOptions(
                        layout: [1,1,2],               // required
                        styles: Skyflow.Styles,        // optional
                        errorTextStyles: Skyflow.Styles //optional
                        )
```
### Step 2: Create Composable Elements
Composable Elements use the following schema:

```swift
let composableElementInput = Skyflow.CollectElementInput(
    table: String,                  // optional, the table this data belongs to
    column: String,                 // optional, the column into which this data should be inserted
    inputStyles: Skyflow.Styles,     // optional styles that should be applied to the form element
    labelStyles: Skyflow.Styles,     // optional styles that will be applied to the label of the collect element
    errorTextStyles: Skyflow.Styles, // optional styles that will be applied to the errorText of the collect element
    label: String,                   // optional label for the form element
    placeholder: String,             // optional placeholder for the form element
    altText: String,                 // (DEPRECATED) optional that acts as an initial value for the collect element
    validations: ValidationSet,      // optional set of validations for the input element
    type: Skyflow.ElementType,       // Skyflow.ElementType enum
)
```
The `table` and `column` fields indicate which table and column in the vault the Element correspond to.
**Note**: 
-   Use dot delimited strings to specify columns nested inside JSON fields (e.g. `address.street.line1`)
 
The `inputStyles` parameter accepts a Skyflow.Styles object which consists of multiple `Skyflow.Styles` objects which should be applied to the form element in the following states:
 
- `base`: all other variants inherit from these styles
- `complete`: applied when the Element has valid input
- `empty`: applied when the Element has no input
- `focus`: applied when the Element has focus
- `invalid`: applied when the Element has invalid input
 
Each Style object accepts the following properties, please note that each property is optional:
 
```swift
let style = Skyflow.Style(
    borderColor: UIColor,            // optional
    cornerRadius: CGFloat,           // optional
    padding: UIEdgeInsets,           // optional
    borderWidth: CGFloat,            // optional
    font: UIFont,                   // optional
    textAlignment: NSTextAlignment,  // optional
    textColor: UIColor               // optional
)
```
An example Skyflow.Styles object
```swift
let styles = Skyflow.Styles(
    base: style,                    // optional
    complete: style,                // optional
    empty: style,                   // optional
    focus: style,                   // optional
    invalid: style                  // optional
)
```
 
The `labelStyles` and `errorTextStyles` fields accept the above mentioned `Skyflow.Styles` object which are applied to the `label` and `errorText` text views respectively.
 
The states that are available for `labelStyles` are `base` and `focus`.
 
The state that is available for `errorTextStyles` is only the `base` state, it shows up when there is some error in the composable element.
 
The parameters in `Skyflow.Style` object that are respected for `label` and `errorText` text views are
- padding
- font
- textColor
- textAlignment
 
Other parameters in the `Skyflow.Style` object are ignored for `label` and `errorText` text views.
 
Finally, the `type` parameter takes a Skyflow.ElementType. Each type applies the appropriate regex and validations to the form element. 

The iOS SDK supports the following composable elements:

- `INPUT_FIELD`
- `CARDHOLDER_NAME`
- `CARD_NUMBER`
- `EXPIRATION_DATE`
- `CVV`
- `PIN`
- `EXPIRATION_YEAR`
- `EXPIRATION_MONTH`

**Note**: Only when the entered value in the below composable elements is valid, the focus shifts automatically. The element types are:

- `CARD_NUMBER`
- `EXPIRATION_DATE`
- `EXPIRATION_MONTH`
- `EXPIRATION_YEAR`

The `INPUT_FIELD` type is a custom UI element without any built-in validations. See the section on [validations](#validations) for more information on validations.
 
Along with `CollectElementInput`, you can define other options in the `CollectElementOptions` object which is described below.
 
```swift
Skyflow.CollectElementOptions(
  required: Boolean,               // Indicates whether the field is marked as required. Defaults to 'false'
  enableCardIcon: Boolean,         // Indicates whether card icon should be enabled (only for CARD_NUMBER inputs)
  format: String,                  // Format for the element 
  translation: [Character: String] // Indicates the allowed data type value for format.
)
```
- `required`: Indicates whether the field is marked as required or not. Default is `false`.
- `enableCardIcon`: Indicates whether the icon is visible for the CARD_NUMBER element. Default is `true`.
- `format`:  A string value that indicates the format pattern applicable to the element type. Only applicable to EXPIRATION_DATE, CARD_NUMBER, EXPIRATION_YEAR, and INPUT_FIELD elements.
   For INPUT_FIELD elements,
     -  the length of `format` determines the expected length of the user input.
     - if `translation` isn't specified, the `format` value is considered a string literal.
- `translation`: A dictionary of key/value pairs, where the key is a character that appears in `format` and the value is a regex pattern of acceptable inputs for that character. Each key can only appear once. Only applicable for INPUT_FIELD elements.

The accepted EXPIRATION_DATE values are

- `mm/yy` (default)
- `mm/yyyy`
- `yy/mm`
- `yyyy/mm`

The accepted EXPIRATION_YEAR values are

- `yy` (default)
- `yyyy`

Once the `Skyflow.CollectElementInput` and `Skyflow.CollectElementOptions` objects are defined, add to the container using the ```create(input: CollectElementInput, options: CollectElementOptions)``` method as shown below. The `input` param takes a `Skyflow.CollectElementInput` object as defined above and the `options` parameter takes an `Skyflow.CollectElementOptions` object as described below:
 
```swift
let composableElementInput = Skyflow.CollectElementInput(
    table: String,                  // the table this data belongs to
    column: String,                 // the column into which this data should be inserted
    inputStyles: Skyflow.Styles,     // optional styles that should be applied to the form element
    labelStyles: Skyflow.Styles,     // optional styles that will be applied to the label of the collect element
    errorTextStyles: Skyflow.Styles, // optional styles that will be applied to the errorText of the collect element
    label: String,                   // optional label for the form element
    placeholder: String,             // optional placeholder for the form element
    altText: String,                 // (DEPRECATED) optional that acts as an initial value for the collect element
    validations: ValidationSet,      // optional set of validations for the input element
    type: Skyflow.ElementType,       // Skyflow.ElementType enum
)

let collectElementOptions = Skyflow.CollectElementOptions(
    required: false,  // indicates whether the field is marked as required. Defaults to 'false',
    enableCardIcon: true, // indicates whether card icon should be enabled (only for CARD_NUMBER inputs)
    format: "mm/yy" // Format for the element
)

let element = container?.create(input: composableElementInput, options: collectElementOptions)
```
## Step 3: Mount Elements to the Screen

To specify where the Elements will be rendered on the screen, create a parent UIView (like UIStackView, etc) and you can add composable elements view using `container?.getComposableView()`, it as a subview programmatically.
 
```swift
let stackView = UIStackView()
do {
    let composableView = try container?.getComposableView()
    stackView.addArrangedSubview(composableView)
} catch {
    print(error)
}
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
## Step 4: Collect data from elements
When you submit the form, call the `collect(options: Skyflow.CollectOptions? = nil, callback: Skyflow.Callback)` method on the container object. 
The options parameter takes a `Skyflow.CollectOptions` object as shown below:

- `tokens`: Whether or not tokens for the collected data are returned. Defaults to 'true'
- `additionalFields`: Non-PCI elements data to insert into the vault, specified in the records object format.
- `upsert`: To support upsert operations, the table containing the data and a column marked as unique in that table.

```swift
// Non-PCI records
let nonPCIRecords = ["table": "persons", "fields": [["gender": "MALE"]]]
// Upsert
let upsertOptions = [["table": "cards", "column": "cardNumber"]] as [[String : Any]]
// Send the non-PCI records as additionalFields of InsertOptions (optional) and apply upsert using `upsert` field of InsertOptions (optional)

let options = Skyflow.CollectOptions(tokens: true, additionalFields: nonPCIRecords, upsert: upsertOptions)
 
//Custom callback - implementation of Skyflow.callback
let insertCallback = InsertCallback() 
container?.collect(callback: insertCallback, options: options)
```
End to end example of collecting data with Composable Elements

```swift

//Initialize skyflow configuration.
let config = Skyflow.Configuration(vaultID: VAULT_ID, vaultURL: VAULT_URL, tokenProvider: demoTokenProvider)
 
//Initialize skyflow client.
let skyflowClient = Skyflow.initialize(config)

let containerOptions = ContainerOptions(layout: [1,2], styles: Styles(base: Style(borderColor: UIColor.gray)), errorTextStyles: Styles(base: Style(textColor: UIColor.red)))
//Create a Composable Container.
let container = self.skyflow?.container(type: Skyflow.ContainerType.COMPOSABLE, options: containerOptions)
 
//Create Skyflow.Styles with individual Skyflow.Style variants.
let baseStyle = Skyflow.Style(borderColor: UIColor.blue)
let baseTextStyle = Skyflow.Style(textColor: UIColor.black)
let completeStyle = Skyflow.Style(borderColor: UIColor.green)
let focusTextStyle = Skyflow.Style(textColor: UIColor.red)
let inputStyles = Skyflow.Styles(base: baseStyle, complete: completeStyle)
let labelStyles = Skyflow.Styles(base: baseTextStyle, focus: focusTextStyle)
let errorTextStyles = Skyflow.Styles(base: baseTextStyle)
 
// Create Composable Elements.

let cardHolderNameElementInput = Skyflow.CollectElementInput(
    table: "cards",
    column: "first_name",
    inputStyles: inputStyles,
    labelStyles: labelStyles,
    errorTextStyles: errorTextStyles,
    label: "first name",
    placeholder: "first name",
    type: Skyflow.ElementType.CARDHOLDER_NAME
)
// Create an option to require the element.
let requiredOption = Skyflow.CollectElementOptions(required: true) 

// Create a Composable Element from the Composable Container.
let cardHolderNameElement = container?.create(input: cardHolderNameElementInput, options: requiredOption)
 
 
let cardNumberElementInput = Skyflow.CollectElementInput(
    table: "cards",
    column: "cardNumber",
    inputStyles: inputStyles,
    labelStyles: labelStyles,
    errorTextStyles: errorTextStyles,
    label: "card number",
    placeholder: "card number",
    type: Skyflow.ElementType.CARD_NUMBER
)
 
let cardNumberElement = container?.create(input: cardNumberElementInput, options: requiredOption)

let cvvElementInput = Skyflow.CollectElementInput(
    table: "cards",
    column: "cvv",
    inputStyles: inputStyles,
    labelStyles: labelStyles,
    errorTextStyles: errorTextStyles,
    label: "cvv",
    placeholder: "cvv",
    type: Skyflow.ElementType.CVV
)
 
let cvvElement = container?.create(input: cvvElementInput, options: requiredOption)

// Can interact with this object as a normal UIView Object and add to View
let stackView = UIStackView()
do {
    let composableView = try container?.getComposableView()
    stackView.addArrangedSubview(composableView)
} catch {
    print(error)
}
 
// Non-PCI records
let nonPCIRecords = ["table": "persons", "fields": [["gender": "MALE"]]]
 
 //Upsert options
let upsertOptions = [["table": "cards", "column": "cardNumber"]] as [[String : Any]]
 
// Send the Non-PCI records as additionalFields of CollectOptions (optional) and apply upsert using optional field `upsert` of CollectOptions.
let collectOptions = Skyflow.CollectOptions(tokens: true, additionalFields: nonPCIRecords, upsert: upsertOptions) 
 
 
//Implement a custom Skyflow.Callback to call on Insertion success/failure.
public class InsertCallback: Skyflow.Callback {
  public func onSuccess(_ responseBody: Any) {
      print(responseBody)
  }
   public func onFailure(_ error: Any) {
      print(error)
  }
}

// Initialize custom Skyflow.Callback.
let insertCallback = InsertCallback()
 
// Call collect method on CollectContainer.
container?.collect(callback: insertCallback, options: collectOptions)
```

### Sample Response:

```
{
    "records": [ {
        "table": "cards",
        "fields": {
            "cardNumber": "f3907186-e7e2-466f-91e5-48e12c2bcbc1"
        }
    }, {
        "table": "persons",
        "fields": {
            "gender": "12f670af-6c7d-4837-83fb-30365fbc0b1e",
        }
    }]
}
```
[For information on validations, see validations.](#validations)



## Set an event listener on Composable Elements:
You can communicate with Skyflow Elements by listening to element events:

```swift
element!.on(eventName: Skyflow.EventName) { _ in
    // handle function
}
```

The SDK supports four events:

- CHANGE: Triggered when the Element's value changes.
- READY: Triggered when the Element is fully rendered.
- FOCUS: Triggered when the Element gains focus.
- BLUR: Triggered when the Element loses focus.

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

`Note`: 
values of SkyflowElements will be returned in element state object only when `env` is `DEV`, else it is empty string i.e, '', but in case of CARD_NUMBER type element when the `env` is `PROD` for all the card types except AMEX, it will return first eight digits, for AMEX it will return first six digits and rest all digits in masked format.

#### Example Usage of Event Listener on Composable Elements

```swift
// create skyflow client with loglevel:"DEBUG"
let config = Skyflow.Configuration(
    vaultID: VAULT_ID,
    vaultURL: VAULT_URL,
    tokenProvider: demoTokenProvider,
    options: Skyflow.Options(logLevel: Skyflow.LogLevel.DEBUG)
)

let skyflowClient = Skyflow.initialize(config)

let containerOptions = ContainerOptions(layout: [2], styles: Styles(base: Style(borderColor: UIColor.gray)), errorTextStyles: Styles(base: Style(textColor: UIColor.red)))
//Create a Composable Container.
let container = self.skyflow?.container(type: Skyflow.ContainerType.COMPOSABLE, options: containerOptions)

// Create a CollectElementInput
let cardNumberInput = Skyflow.CollectElementInput(
    table: "cards",
    column: "cardNumber",
    type: Skyflow.ElementType.CARD_NUMBER,
    )
let cardHolderNameInput = Skyflow.CollectElementInput(
    table: "cards",
    column: "cardHolderName",
    type: Skyflow.ElementType.CARDHOLDER_NAME,
    )    

let cardNumber = container?.create(input: cardNumberInput)
let cardHolderName = container?.create(input: cardHolderNameInput)

let stackView = UIStackView()
do {
    let composableView = try container?.getComposableView()
    stackView.addArrangedSubview(composableView)
} catch {
    print(error)
}
// subscribing to CHANGE event, which gets triggered when element changes
cardNumber.on(eventName: Skyflow.EventName.CHANGE) { state in
    // Your implementation when Change event occurs
    print(state)
}

cardHolderName.on(eventName: Skyflow.EventName.CHANGE) { state in
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
    "isValid": true,
    "value": "4111111111111111"
]
[
    "elementType": Skyflow.ElementType.CARDHOLDER_NAME,
    "isEmpty": false,
    "isFocused": true,
    "isValid": true,
    "value": "John"
]

```
##### Sample Element state object when `env` is `PROD`
```swift
[
    "elementType": Skyflow.ElementType.CARD_NUMBER,
    "isEmpty": false,
    "isFocused": true,
    "isValid": true,
    "value": "41111111XXXXXXXX"
]
[
    "elementType": Skyflow.ElementType.CARDHOLDER_NAME,
    "isEmpty": false,
    "isFocused": true,
    "isValid": true,
    "value": ""
]
```
### Update composable elements
You can update composable element properties with the `update` interface.

The `update` interface takes the below object:
```swift
let updateElement =  Skyflow.CollectElementInput(
    table: String,                   // optional the table this data belongs to
    column: String,                  // optional the column into which this data should be inserted
    inputStyles: Skyflow.Styles,     // optional styles that should be applied to the form element
    labelStyles: Skyflow.Styles,     // optional styles that will be applied to the label of the collect element
    errorTextStyles: Skyflow.Styles, // optional styles that will be applied to the errorText of the collect element
    label: String,                   // optional label for the form element
    placeholder: String,             // optional placeholder for the form element
    altText: String,                 // (DEPRECATED) optional that acts as an initial value for the collect element
    validations: ValidationSet,      // optional set of validations for the input element
)
```
Only include the properties that you want to update for the specified composable element.

Properties your provided when you created the element remain the same until you explicitly update them.

`Note`: You can't update the type property of an element.

### End to end example
```swift
// create skyflow client with loglevel:"DEBUG"
let config = Skyflow.Configuration(
    vaultID: VAULT_ID,
    vaultURL: VAULT_URL,
    tokenProvider: demoTokenProvider,
    options: Skyflow.Options(logLevel: Skyflow.LogLevel.DEBUG)
)

let skyflowClient = Skyflow.initialize(config)

let containerOptions = ContainerOptions(layout: [2], styles: Styles(base: Style(borderColor: UIColor.gray)), errorTextStyles: Styles(base: Style(textColor: UIColor.red)))
//Create a Composable Container.
let container = self.skyflow?.container(type: Skyflow.ContainerType.COMPOSABLE, options: containerOptions)

// Create a CollectElementInput
let cardNumberInput = Skyflow.CollectElementInput(
    table: "cards",
    column: "cardNumber",
    type: Skyflow.ElementType.CARD_NUMBER,
    )
let cardHolderNameInput = Skyflow.CollectElementInput(
    table: "cards",
    column: "cardHolderName",
    type: Skyflow.ElementType.CARDHOLDER_NAME,
    )    

let cardNumber = container?.create(input: cardNumberInput)
let cardHolderName = container?.create(input: cardHolderNameInput)

let stackView = UIStackView()
do {
    let composableView = try container?.getComposableView()
    stackView.addArrangedSubview(composableView)
} catch {
    print(error)
}
// Update table, column, inputStyles properties on cardNumber.
cardNumber.update(update: CollectElementInput(
    table: "cards",
    column: "cardHolderName",
    inputStyles: Skyflow.Styles(base: Style(borderColor: UIColor.red))
))
let lengthRule = LengthMatchRule(
                    minLength: 5,
                    maxLength: 16,
                    error: "Must be between 5 and 16 digits")

// Update validations and placeholder property on cardHolderName.
cardHolderName.update(update: CollectElementInput(
    placeholder: "cardHolderName",
    validations: ValidationSet(rules: [lengthRule]))
))
```

### Set an event listener on a composable container

Currently, the SDK supports one event:

 - `SUBMIT`: Triggered when the Enter key is pressed in any container element.
  
The handler function(void) -> void is a callback function you provide that's called when the `SUBMIT` event fires.

#### Example

```swift
let containerOptions = ContainerOptions(layout: [1], styles: Styles(base: Style(borderColor: UIColor.gray)), errorTextStyles: Styles(base: Style(textColor: UIColor.red)))
//Create a Composable Container.
let composableContainer = self.skyflow?.container(type: Skyflow.ContainerType.COMPOSABLE, options: containerOptions)

// Creating the element.
let cardNumberInput = Skyflow.CollectElementInput(
    table: "cards",
    column: "cardNumber",
    type: Skyflow.ElementType.CARD_NUMBER,
    )
let cardNumber = composableContainer?.create(input: cardNumberInput)

// get composable view and mount it
let stackView = UIStackView()
do {
    let composableView = try composableContainer?.getComposableView()
    stackView.addArrangedSubview(composableView)
} catch {
    print(error)
}
// Subscribing to the `SUBMIT` event, which gets triggered when the user hits `enter` key in any container element input.
composableContainer?.on(eventName: .SUBMIT){
    // Your implementation when the SUBMIT(enter) event occurs.
    print('Submit Event Listener is being Triggered.')
}

```

# Securely revealing data client-side
-  [**Retrieving data from the vault**](#retrieving-data-from-the-vault)
-  [**Using Skyflow Elements to reveal data**](#using-skyflow-elements-to-reveal-data)
-  [**UI Error for Reveal Elements**](#ui-error-for-reveal-elements)
-  [**Set token for Reveal Elements**](#set-token-for-reveal-elements)
-  [**Set and clear altText for Reveal Elements**](#set-and-clear-alttext-for-reveal-elements)
 
## Retrieving data from the vault
For non-PCI use-cases, retrieving data from the vault and revealing it in the mobile can be done either using the SkyflowID's or tokens as described below
 
- ### Using Skyflow tokens
    To retrieve record data using tokens, use the `detokenize(records)` method. The records parameter takes a Dictionary object that contains tokens for `record` values to fetch
    ```swift
    [
      "records": [
        [
          "token": String,
          "redaction": Skyflow.RedactionType // Optional. Redaction to apply for retrieved data.     
        ]
      ]
    ]
   ```
  Note: `redaction` defaults to [RedactionType.PLAIN_TEXT](#redaction-types).
 
The following example code makes a detokenize call to reveal the masked value of a token:

```swift
  let getCallback = GetCallback()   // Custom callback - implementation of Skyflow.Callback
 
  let records = [
                  "records": [
                    [
                      "token": "45012507-f72b-4f5c-9bf9-86b133bae719",
                    ],
                    [
                      "token": "1r434532-6f76-4319-bdd3-96281e051051",
                      "redaction": Skyflow.RedactionType.MASKED
                    ]
                  ]
                ] as [String: Any]
 
  skyflowClient.detokenize(records: records, callback: getCallback)
  ```
  The sample response:
  ```json
  {
    "records": [
      {
        "token": "131e70dc-6f76-4319-bdd3-96281e051051",
        "value": "1990-01-01"
      },
      {
        "token": "1r434532-6f76-4319-bdd3-96281e051051",
        "value": "xxxxxxer",
      }
     ]
  }
  ```
 
- ### Using Skyflow ID's or Unique Column Values
    For retrieving data from the vault, use the `get(records: JSONObject, options: GetOptions? = GetOptions(), callback: Skyflow.Callback)` method.
    The `records` parameter takes a Dictionary object that contains `records` to be fetched as shown below. Each object inside array should contain:

    - Either an array of Skyflow IDs to fetch
    - Or a column name and an array of column values
    
    The second parameter, `options`, is a `GetOptions` object that retrieves tokens of Skyflow IDs.

  Notes:
  - You can use either Skyflow IDs or unique values to retrieve records. You can't use both at the same time.
  - GetOptions parameter is applicable only for retrieving tokens using Skyflow ID.
  - You can't pass GetOptions along with the redaction type.
  - tokens defaults to false.

 ```swift
    [
      "records": [
        [
          "ids": ArrayList<String>(),           // Array of SkyflowID's of the records to be fetched
          "table": String,                      // Name of table holding the above skyflow_id's
          "redaction": Skyflow.RedactionType    // Redaction to be applied to retrieved data
        ],
        [
          "columnValues": ArrayList<String>(),     // Array of column values of the records to be fetched
          "table": String,                         // Name of table holding the above skyflow_id's
          "columnName": String,                    // A unique column name
          "redaction": Skyflow.RedactionType       // Redaction to be applied to retrieved data
        ],
      ]
    ]
 ```
 ### Redaction Types
  There are 4 accepted values in Skyflow.RedactionTypes:  
  - `PLAIN_TEXT`
  - `MASKED`
  - `REDACTED`
  - `DEFAULT`  
  
 An example of get call to fetch records:
  ```swift
  let getCallback = GetCallback() // Custom callback - implementation of Skyflow.Callback
 
  let skyflowIDs = ["f8d8a622-b557-4c6b-a12c-c5ebe0b0bfd9"]
  let record = ["ids": skyflowIDs, "table": "cards", "redaction": Skyflow.RedactionType.PLAIN_TEXT] as [String : Any]
  
  let columnValues = ["12345"]
  let columnRecord = ["columnValues": columnValues,"columnName": "card_pin", "table": "cards", "redaction": Skyflow.RedactionType.PLAIN_TEXT] as [String : Any]
  
  let invalidID = ["invalid skyflow ID"]
  let badRecord = ["ids": invalidID, "table": "cards", "redaction": Skyflow.RedactionType.PLAIN_TEXT] as [String : Any]
 
  let records = ["records": [record,columnRecord, badRecord]]
 
  skyflowClient.get(records: records, callback: getCallback)
  ```
 
  The sample response:
  ```json
  {
    "records": [{
        "fields": {
            "card_number": "4111111111111111",
            "cvv": "127",
            "expiry_date": "11/35",
            "fullname": "myname",
            "id": "f8d8a622-b557-4c6b-a12c-c5ebe0b0bfd9"
          },
          "table": "cards"
      },{
        "fields": {
            "card_number": "4111111111111111",
            "cvv": "345",
            "card_pin":"12345"
            "expiry_date": "12/29",
            "fullname": "joey",
            "id": "ed2e7851-9f84-4d70-9e5d-182f6d8d4fa3"
          },
        "table": "cards"
      }
    ],
    "errors": [ {
       "error": {
          "code": "404",
          "description": "No Records Found"
        },
        "ids": ["invalid skyflow id"]
    }]
  }
 ```
  
  An example of get call to fetch tokens:

  ```swift
  let getCallback = GetCallback() // Custom callback - implementation of Skyflow.Callback
 
  let skyflowIDs = ["f8d8a622-b557-4c6b-a12c-c5ebe0b0bfd9", "da26de53-95d5-4bdb-99db-8d8c66a35ff9"]
  let record = ["ids": skyflowIDs, "table": "cards", "redaction": Skyflow.RedactionType.PLAIN_TEXT] as [String : Any]
   
  let invalidID = ["invalid skyflow ID"]
  let badRecord = ["ids": invalidID, "table": "cards", "redaction": Skyflow.RedactionType.PLAIN_TEXT] as [String : Any]
 
  let records = ["records": [record, badRecord]]
 
  skyflowClient.get(records: records, options: GetOptions(tokens: true), callback: getCallback)
  ```
 The sample Response:
  ```json
  {
  "records": [
    {
      "fields": {
        "card_number": "9802-3257-3113-0294",
        "expiry_date": "45012507-f72b-4f5c-9bf9-86b133bae719",
        "fullname": "131e2507-f72b-4f5c-9bf9-86b133bae719",
        "id": "f8d8a622-b557-4c6b-a12c-c5ebe0b0bfd9"
      },
      "table": "cards"
    },
    {
      "fields": {
        "card_number": "0294-3213-3157-9802",
        "expiry_date": "131e2507-f72b-4f5c-9bf9-86b133bae719",
        "fullname": "45012507-f72b-4f5c-9bf9-86b133bae719",
        "id": "ed2e7851-9f84-4d70-9e5d-182f6d8d4fa3"
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
      "ids": ["invalid skyflow id"]
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
    token: String,                       // optional, token of the data being revealed
    inputStyles: Skyflow.Styles(),       // optional, styles to be applied to the element
    labelStyles: Skyflow.Styles(),       // optional, styles to be applied to the label of the reveal element
    errorTextStyles: Skyflow.Styles(),   // optional styles that will be applied to the errorText of the reveal element
    label: "cardNumber",                 // optional, label for the element,
    altText: "XXXX XXXX XXXX XXXX",      // optional, string that is shown before reveal, will show token if it is not provided
    redaction: Skyflow.RedactionType,    // optional. Redaction to apply for retrieved data. E.g. RedactionType.MASKED
)
```
`Note`: 
- `token` is optional only if it is being used in invokeConnection()
- `redaction` defaults to [`RedactionType.PLAIN_TEXT`](#redaction-types).

 
The `inputStyles` parameter accepts a styles object as described in the [previous section](#step-2-create-a-collect-element) for collecting data but the only state available for a reveal element is the base state. 
 
The `labelStyles` and `errorTextStyles` fields accept the above mentioned `Skyflow.Styles` object as described in the [previous section](#step-2-create-a-collect-element), the only state available for a reveal element is the base state.
 
The `inputStyles`, `labelStyles` and  `errorTextStyles` parameters accepts a styles object as described in the [previous section](#step-2-create-a-collect-element) for collecting data but only a single variant is available i.e. base. 
 
An example of a inputStyles object:
 
```swift
let inputStyles = Skyflow.Styles(base: Skyflow.Style(borderColor: UIColor.green))
```
 
An example of a labelStyles object:
 
```swift
let labelStyles = Skyflow.Styles(base: Skyflow.Style(font: UIFont (name: "GILLSANSCE-ROMAN", size: 12))))
```
 
An example of a errorTextStyles object:
 
```swift
let labelStyles = Skyflow.Styles(base: Skyflow.Style(textColor: UIColor.red))
```
Along with `RevealElementInput`, you can define other options in the `RevealElementOptions` object as described below:
```swift
Skyflow.RevealElementOptions(
  format: String, // Format for the element.
  translation: [Character: String] // Indicates the allowed data type value for format
  enableCopy: Boolean, // Indicates whether to enable the copy icon in reveal elements to copy text to clipboard. Defaults to 'false'
)
```
- `format`: A string value that indicates how the  element should display the value, including placeholder characters that map to keys `translation` If `translation` isn't specified, the `format` value is considered a string literal.
- `translation`: A dictionary of key/value pairs, where the key is a character that appears in `format` and the value is a regex pattern of acceptable inputs for that character. Each key can only appear once. Defaults to `[ "X": "[0-9]"]`.
- `enableCopy`: Indicates whether to enable the copy icon in reveal elements to copy text to clipboard.

Reveal Element Options examples:

Example 1:
```swift
Skyflow.RevealElementOptions(
  format:   "(XXX) XXX-XXXX",
  translation: [ "X": "[0-9]"] 
)
```
Value from vault: "1234121234"

Value displayed in element: "(123) 412-1234"

Example 2:
```swift
Skyflow.RevealElementOptions(
  format:   "XXXX-XXXXXX-XXXXX",
  translation: [ "X": "[0-9]"] 
)
```
Value from vault: "374200000000004"

Value displayed in element: "3742-000000-00004"

Once you've defined a `Skyflow.RevealElementInput` object and `Skyflow.RevealElementOptions`, you can use the `create()` method of the container to create the Element as shown below:
 
```swift
let element = container.create(input: revealElementInput, options: Skyflow.RevealElementOptions(format: "XXXX-XXXXXX-XXXXX",
translation: ["X": "[0-9]"] 
))
```

### Step 3: Mount Elements to the Screen
 
Elements used for revealing data are mounted to the screen the same way as Elements used for collecting data. Refer to Step 3 of the [section above](#step-3-mount-elements-to-the-screen).
 
### Step 4: Reveal data
When the sensitive data is ready to be retrieved and revealed, call the `reveal()` method on the container as shown below:
```swift
let revealCallback = RevealCallback()  // Custom callback - implementation of Skyflow.Callback
container.reveal(callback: revealCallback)
```
 
### UI Error for Reveal Elements
 
Helps to display custom error messages on the Skyflow Elements through the methods `setError` and `resetError` on the elements.
 
`setError(error: String)` method is used to set the error text for the element, when this method is trigerred, all the current errors present on the element will be overridden with the custom error message passed. This error will be displayed on the element until `resetError()` is trigerred on the same element.
 
`resetError()` method is used to clear the custom error message that is set using `setError`.
 
### Set token for Reveal Elements
 
The `setToken(value: String)` method can be used to set the token of the Reveal Element. If no altText is set, the set token will be displayed on the UI as well. If altText is set, then there will be no change in the UI but the token of the element will be internally updated.
 
### Set and Clear altText for Reveal Elements
 
The `setAltText(value: String)` method can be used to set the altText of the Reveal Element. This will cause the altText to be displayed in the UI regardless of whether the token or value is currently being displayed.
 
`clearAltText()` method can be used to clear the altText, this will cause the element to display the token or actual value of the element. If the element has no token, the element will be empty.
 
### Reveal data with Skyflow Elements
#### End-to-end example of revealing data with Skyflow Elements
```swift
// Initialize skyflow configuration
let config = Skyflow.Configuration(vaultID: <VAULT_ID>, vaultURL: <VAULT_URL>, tokenProvider: demoTokenProvider)

// Initialize skyflow client
let skyflowClient = Skyflow.initialize(config)

// Create a Reveal Container
let container = skyflowClient.container(type: Skyflow.ContainerType.REVEAL)

// Create Skyflow.Styles with individual Skyflow.Style variants
let baseStyle = Skyflow.Style(borderColor: UIColor.blue)
let baseTextStyle = Skyflow.Style(textColor: UIColor.BLACK)
let inputStyles = Skyflow.Styles(base: baseStyle)
let labelStyles = Skyflow.Styles(base: baseTextStyle)
let errorTextStyles = Skyflow.Styles(base: baseTextStyle)

// Create Reveal Elements
let cardNumberInput = Skyflow.RevealElementInput(
    token: "b63ec4e0-bbad-4e43-96e6-6bd50f483f75",
    inputStyles: inputStyles,
    labelStyles: labelStyles,
    errorTextStyles: errorTextStyles,
    label: "cardnumber",
    altText: "XXXX XXXX XXXX XXXX",
    redaction: SKyflow.RedactionType.MASKED
)

let cardNumberElement = container?.create(input: cardNumberInput)

let cvvInput = Skyflow.RevealElementInput(
    token: "89024714-6a26-4256-b9d4-55ad69aa4047",
    inputStyles: inputStyles,
    labelStyles: labelStyles,
    errorTextStyles: errorTextStyles,
    label: "cvv",
    altText: "XXX"
)
let cvvElement = container?.create(input: cvvInput)

let expiryDateInput = Skyflow.RevealElementInput(
    token: "a4b24714-6a26-4256-b9d4-55ad69aa4047",
    inputStyles: inputStyles,
    labelStyles: labelStyles,
    errorTextStyles: errorTextStyles,
    label: "expiryDate",
    altText: "MM/YYYY"
)
let expiryDateElement = container?.create(input: expiryDateInput)

// Can interact with these objects as a normal UIView Object and add to View

// set error to the element
cvvElement!.setError("custom error")
// reset error to the element
cvvElement!.resetError()

// Implement a custom Skyflow.Callback to be called on Reveal success/failure
public class RevealCallback: Skyflow.Callback {
    public func onSuccess(_ responseBody: Any) {
        print(responseBody)
    }
    public func onFailure(_ error: Any) {
        print(error)
    }
}

// Initialize custom Skyflow.Callback
let revealCallback = RevealCallback()

// Call reveal method on RevealContainer
container?.reveal(callback: revealCallback)

```
 
The response below shows that some tokens assigned to the reveal elements get revealed successfully, while others fail and remain unrevealed.
 
#### Sample Response:
```json
{
    "success": [ {
        "token": "b63ec4e0-bbad-4e43-96e6-6bd50f483f75"
    },
    {
        "token": "89024714-6a26-4256-b9d4-55ad69aa4047"
    }],
    "errors": [ {
        "id": "a4b24714-6a26-4256-b9d4-55ad69aa4047",
        "error": {
            "code": 404,
            "description": "Tokens not found for a4b24714-6a26-4256-b9d4-55ad69aa4047"
        }
    }]
}
```
 
## Reporting a Vulnerability
 
If you discover a potential security issue in this project, please reach out to us at security@skyflow.com. Please do not create public GitHub issues or Pull Requests, as malicious actors could potentially view them.


