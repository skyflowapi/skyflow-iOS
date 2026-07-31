# skyflow-iOS
---
Skyflow's iOS SDK can be used to securely collect, tokenize, and display sensitive data in the mobile without exposing your front-end infrastructure to sensitive data. 
 
[![CI](https://img.shields.io/static/v1?label=CI&message=passing&color=green?style=plastic&logo=github)](https://github.com/skyflowapi/skyflow-ios/actions)
[![GitHub release](https://img.shields.io/github/v/release/skyflowapi/skyflow-ios.svg)](https://github.com/skyflowapi/skyflow-ios/releases)
[![License](https://img.shields.io/github/license/skyflowapi/skyflow-ios)](https://github.com/skyflowapi/skyflow-ios/blob/main/LICENSE)
 
# Table of Contents
- [Upgrading from PDB to FlowDB](#upgrading-from-pdb-to-flowdb)
- [Quick Start](#quick-start)
    - [Collect data](#collect-data)
    - [Reveal data](#reveal-data)
- [Installation](#installation)
    - [Requirements](#requirements)
    - [Configuration](#configuration)
- [Initializing Skyflow-iOS](#initializing-skyflow-ios)
- [Securely collecting data client-side](#securely-collecting-data-client-side)
    - [Using Skyflow Elements to collect data](#using-skyflow-elements-to-collect-data)
    - [Using Skyflow Elements to update data](#using-skyflow-elements-to-update-data)
    - [Validations](#validations)
    - [Event Listener on Collect Elements](#event-listener-on-collect-elements)
    - [UI Error for Collect Elements](#ui-error-for-collect-elements)
    - [Set and Clear value for Collect Elements (DEV ENV ONLY)](#set-and-clear-value-for-collect-elements-dev-env-only)
- [Securely collecting data client-side using Composable Elements](#securely-collecting-data-client-side-using-composable-elements)
    - [When to use Composable vs. Basic Elements](#when-to-use-composable-vs-basic-elements)
    - [Using Skyflow Composable Elements to collect data](#using-skyflow-composable-elements-to-collect-data)
    - [Using Skyflow Composable Elements to update data](#using-skyflow-composable-elements-to-update-data)
- [Securely revealing data client-side](#securely-revealing-data-client-side)
    - [Using Skyflow Elements to reveal data](#using-skyflow-elements-to-reveal-data)
- [Error Handling Reference](#error-handling-reference)
- [Reporting a Vulnerability](#reporting-a-vulnerability)
# Upgrading from PDB to FlowDB
Starting in **v1.26.0-beta.1**, Collect and Reveal run on Skyflow's FlowDB backend. If you're upgrading from an earlier version, a few things changed:

- **`CollectElementInput.altText` is deprecated and now a no-op** - it's accepted but never read or stored. Use `placeholder` instead.
- **`CollectOptions.tokens` (`Bool`) was removed** - tokens are always returned now; there's no way to opt out.
- **`CollectRecord`/`RevealRecord` field names changed**: `fields` → `tokens`, and `skyflowID` (capital `ID`) → `skyflowId`.
- **New, typed `CollectCallback`/`RevealCallback`** are now the recommended way to call `collect()`/`reveal()`, replacing the old untyped `Callback` protocol - `onSuccess`/`onFailure` now hand you typed `CollectResponse`/`RevealResponse`/`SkyflowError` objects instead of raw `Any`. See the [Error Handling Reference](#error-handling-reference) for the new `SkyflowError` shape.
- **Reveal redaction moved off `RevealElementInput`** onto `Skyflow.RevealOptions.tokenGroupRedactions` - the old per-element `redaction`/`tokenGroupName` parameters are gone.
- **New, purely additive support** for update-by-id and upsert: `skyflowId` on `CollectElementInput`, and `Skyflow.AdditionalFields`/`Skyflow.UpsertOption` on `CollectOptions`. Nothing to change if you don't use them.

# Quick Start

### Collect data
Collect a card number and get back a token:

```swift
import Skyflow

// 1. Configure and initialize the client
let config = Skyflow.Configuration(
    vaultID: "<VAULT_ID>",
    vaultURL: "<VAULT_URL>",
    tokenProvider: myTokenProvider // your Skyflow.TokenProvider implementation - see below
)
let skyflowClient = Skyflow.initialize(config)

// 2. Create a container and a Collect Element for the card number
let container = skyflowClient.container(type: Skyflow.ContainerType.COLLECT)
let cardNumberInput = Skyflow.CollectElementInput(
    tableName: "cards",
    column: "card_number",
    type: Skyflow.ElementType.CARD_NUMBER
)
let cardNumberElement = container?.create(input: cardNumberInput)
stackView.addArrangedSubview(cardNumberElement!) // it's a UIView - mount it like any other

// 3. Collect the value and get back a token
let callback = Skyflow.CollectCallback(
    onSuccess: { (response: Skyflow.CollectResponse) in
        print(response.records) 
    },
    onFailure: { (error: Skyflow.SkyflowError) in
        print(error.message)
    }
)
container?.collect(callback: callback)
```

### Reveal data
Reveal a token back to its real value (using the same `skyflowClient` from above):

```swift
// 1. Create a container and a Reveal Element for the token
let revealContainer = skyflowClient.container(type: Skyflow.ContainerType.REVEAL)
let cardNumberReveal = Skyflow.RevealElementInput(
    token: "f3907186-e7e2-466f-91e5-48e12c2bcbc1",
    label: "Card Number"
)
let revealElement = revealContainer?.create(input: cardNumberReveal)
stackView.addArrangedSubview(revealElement!) // shows the real value once revealed

// 2. Reveal it
let revealCallback = Skyflow.RevealCallback(
    onSuccess: { (response: Skyflow.RevealResponse) in
        print(response.records)
    },
    onFailure: { (error: Skyflow.SkyflowError) in
        print(error.message)
    }
)
revealContainer?.reveal(callback: revealCallback)
```

That's the whole round trip both ways - no card data ever touches your app code on the way in, and it's only ever displayed, never returned to your code, on the way out. Everything below covers this in depth: installation, `TokenProvider`, styling, validation, updates, upsert, and more.


# Installation
 
## Requirements
- iOS 13.0 and above
 
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
      logLevel: Skyflow.LogLevel.INFO,    // optional — DEBUG < INFO < WARN < ERROR, default ERROR
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

> **Security warning: never ship a build with `env: .DEV` to production.** `DEV` doesn't just relax a validation check - it unlocks two things that must never reach a real user:
> - The **raw, unmasked field value** becomes readable inside the `CHANGE`/`FOCUS`/`BLUR` [event listener](#event-listener-on-collect-elements) state. In `PROD`, that same state only ever contains an empty string (or, for `CARD_NUMBER`, a partially masked value) - never the full value.
> - [`setValue`/`clearValue`](#set-and-clear-value-for-collect-elements-dev-env-only) become callable and actually take effect.
>
> Both fail **silently** - no crash, no thrown error, either way. If `DEV` ships by accident, the raw PAN/CVV/etc. is simply there, with nothing to flag it. Always confirm `env` is `PROD` (or omitted) before release.
 
 
---
# Securely collecting data client-side
-  [**Using Skyflow Elements to collect data**](#using-skyflow-elements-to-collect-data)
-  [**Using Skyflow Elements to update data**](#using-skyflow-elements-to-update-data)
-  [**Using validations on Collect Elements**](#validations)
-  [**Event Listener on Collect Elements**](#event-listener-on-collect-elements)
-  [**UI Error for Collect Elements**](#ui-error-for-collect-elements)
-  [**Set and Clear value for Collect Elements (DEV ENV ONLY)**](#set-and-clear-value-for-collect-elements-dev-env-only)
 
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
    tableName: String,                  // optional, the table this data belongs to
    column: String,                 // optional, the column into which this data should be inserted
    inputStyles: Skyflow.Styles,     // optional styles that should be applied to the form element
    labelStyles: Skyflow.Styles,     // optional styles that will be applied to the label of the collect element
    errorTextStyles: Skyflow.Styles, // optional styles that will be applied to the errorText of the collect element
    iconStyles: Skyflow.Styles,      // optional styles that will be applied to the card icon of the collect element
    label: String,                   // optional label for the form element
    placeholder: String,             // optional placeholder for the form element
    altText: String,                 // (DEPRECATED) optional that acts as an initial value for the collect element
    type: Skyflow.ElementType,       // Skyflow.ElementType enum
    validations: ValidationSet,      // optional set of validations for the input element
    skyflowId: String,               // optional, the skyflowId of the record to update
)
```
The `table` and `column` fields indicate which table and column in the vault the Element corresponds to. 
**Note**: 
-  Use dot delimited strings to specify columns nested inside JSON fields (e.g. `address.street.line1`)
- `altText` (marked `(DEPRECATED)` in the signature) is dead: `CollectElementInput` accepts it but never reads or stores it, so passing a value has zero effect. `placeholder` is the real, supported way to set initial/placeholder text on a collect element. This should not be confused with `Skyflow.RevealElementInput.altText` (used when [revealing elements](#step-2-create-a-reveal-element)), which shares the same name but is a distinct, fully supported property with no associated deprecation.
 
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
    requiredAstrisk: style        // optional 
)
```
 
The `labelStyles` and `errorTextStyles` fields accept the above mentioned `Skyflow.Styles` object which are applied to the `label` and `errorText` text views respectively.
 
The states that are available for `labelStyles` are `base` and `focus`.

`requiredAstrisk`: Styles applied for the Asterisk symbol in the label. Defaults to red.

The state that is available for `errorTextStyles` is only the `base` state, it shows up when there is some error in the collect element.
 
The parameters in `Skyflow.Style` object that are respected for `label` and `errorText` text views are
- padding
- font
- textColor
- textAlignment
 
Other parameters in the `Skyflow.Style` object are ignored for `label` and `errorText` text views.
 
Finally, the `type` parameter takes a Skyflow.ElementType. Each type applies the appropriate regex and validations to the form element. There are currently 8 types:
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
    tableName: String,                  // the table this data belongs to
    column: String,                 // the column into which this data should be inserted
    inputStyles: Skyflow.Styles,     // optional styles that should be applied to the form element
    labelStyles: Skyflow.Styles,     // optional styles that will be applied to the label of the collect element
    errorTextStyles: Skyflow.Styles, // optional styles that will be applied to the errorText of the collect element
    iconStyles: Skyflow.Styles,      // optional styles that will be applied to the card icon of the collect element
    label: String,                   // optional label for the form element
    placeholder: String,             // optional placeholder for the form element
    altText: String,                 // (DEPRECATED) optional that acts as an initial value for the collect element
    type: Skyflow.ElementType,       // Skyflow.ElementType enum
    validations: ValidationSet,      // optional set of validations for the input element
    skyflowId: String,               // optional, the skyflowId of the record to update
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
When you submit the form, call the `collect(callback: Skyflow.CollectCallback, options: Skyflow.CollectOptions? = Skyflow.CollectOptions())` method on the container object. The options parameter takes a `Skyflow.CollectOptions` object as shown below:
```swift
// Non-PCI records
let nonPCIRecords = Skyflow.AdditionalFields(records: [
    Skyflow.AdditionalFieldsRecord(tableName: "persons", data: ["gender": "MALE"])
])
// Upsert
let upsertOptions = [Skyflow.UpsertOption(tableName: "cards", uniqueColumns: ["cardNumber"], updateType: .UPDATE)]
// Send the non-PCI records as additionalFields of CollectOptions (optional) and apply upsert using `upsert` field of CollectOptions (optional)

let options = Skyflow.CollectOptions(additionalFields: nonPCIRecords)
 
let insertCallback = Skyflow.CollectCallback(
    onSuccess: { (response: Skyflow.CollectResponse) in
        for record in response.records {
            if let error = record.error {
                print("failed:", error, "httpCode:", record.httpCode)
            } else {
                print("success:", record)
            }
        }
    },
    onFailure: { (skyflowError: Skyflow.SkyflowError) in
        print(skyflowError.httpCode, skyflowError.message, skyflowError.grpcCode ?? "", skyflowError.httpStatus ?? "", skyflowError.details ?? "")
    }
)
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
    tableName: "cards",
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
let nonPCIRecords = Skyflow.AdditionalFields(records: [
    Skyflow.AdditionalFieldsRecord(tableName: "persons", data: ["gender": "MALE"])
])
 
 //Upsert options
 let upsertOptions = [Skyflow.UpsertOption(tableName: "cards", uniqueColumns: ["cardNumber"], updateType: .UPDATE)]
 
// Send the Non-PCI records as additionalFields of CollectOptions (optional) and apply upsert using optional field `upsert` of CollectOptions.
let collectOptions = Skyflow.CollectOptions(additionalFields: nonPCIRecords, upsert: upsertOptions) 
 
 
// Initialize a Skyflow.CollectCallback - required by CollectContainer's collect(callback:options:).
// It parses onSuccess into a typed Skyflow.CollectResponse, and onFailure into a typed
// Skyflow.SkyflowError whenever the vault returns that structured shape (see below);
// otherwise onFailure receives the raw error (e.g. a validation SkyflowError) unchanged.
let insertCallback = Skyflow.CollectCallback(
    onSuccess: { (response: Skyflow.CollectResponse) in
        for record in response.records {
            if let error = record.error {
                print("failed:", error, "httpCode:", record.httpCode)
            } else {
                print("success:", record)
            }
        }
    },
    onFailure: { (skyflowError: Skyflow.SkyflowError) in
        print(skyflowError.httpCode, skyflowError.message, skyflowError.grpcCode ?? "", skyflowError.httpStatus ?? "", skyflowError.details ?? "")
    }
)
 
// Call collect method on CollectContainer.
container?.collect(callback: insertCallback, options: collectOptions)
```

#### Skyflow returns tokens for the record you just inserted:
```json
{
    "records": [
        {
            "tableName": "cards",
            "skyflowId": "f1714ef8-8deb-489a-a18d-77e0e007f403",
            "tokens": {
                "cardNumber": [{"token": "f3907186-e7e2-466f-91e5-48e12c2bcbc1", "tokenGroupName": "deterministic_string"}]
            },
            "httpCode": 200
        },
        {
            "tableName": "persons",
            "skyflowId": "77dc3caf-c452-49e1-8625-07219d7567bf",
            "tokens": {
                "gender": [{"token": "12f670af-6c7d-4837-83fb-30365fbc0b1e", "tokenGroupName": "deterministic_string"}]
            },
            "httpCode": 200
        }
    ]
}
```
**Note:** See the [Error Handling Reference](#error-handling-reference) for how successful and failed records are distinguished in this array, and how whole-request failures are shaped.

#### Sample partial error response:
```json
{
    "records": [
        {
            "tableName": "cards",
            "skyflowId": "f1714ef8-8deb-489a-a18d-77e0e007f403",
            "tokens": {
                "cardNumber": [{"token": "f3907186-e7e2-466f-91e5-48e12c2bcbc1", "tokenGroupName": "deterministic_string"}]
            },
            "httpCode": 200
        },
        {
            "error": "Invalid request. Table name table not present for record. Specify a valid table name.",
            "skyflowId": null,
            "tableName": "",
            "httpCode": 400
        }
    ]
}
```

#### If the entire request fails (for example, the vault itself can't be found):
See the [Error Handling Reference](#error-handling-reference) for the whole-request `Skyflow.SkyflowError` shape and how to read its properties.

## Using Skyflow Elements to update data
Updating a record uses the exact same container setup, `CollectElementInput`, `Styles`/`Style`, `CollectElementOptions`, and mounting as [collecting data](#using-skyflow-elements-to-collect-data) - see that section for the full walkthrough of all of those. The only difference for an update: pass `skyflowId` when constructing `CollectElementInput` to target an existing record instead of creating a new one.

```swift
let collectElementInput = Skyflow.CollectElementInput(
    tableName: "cards",
    column: "cardNumber",
    type: Skyflow.ElementType.CARD_NUMBER,
    skyflowId: "431eaa6c-5c15-4513-aa15-29f50babe882" // targets an existing record for update instead of creating a new one
)
let element = container?.create(input: collectElementInput)
```

### Update data from Elements
When the form is ready to submit, call the `collect(options?)` method on the container object. The `options` parameter takes a object of optional parameters as shown below:
- `additionalFields`: A `Skyflow.AdditionalFields` object - non-PCI records to update or insert into the vault alongside whatever's collected from the mounted elements.
- `upsert`: An array of `Skyflow.UpsertOption` objects to support upsert while collecting data from Skyflow elements. Each option specifies the `tableName`, the `uniqueColumns` used to match existing records, and an optional `updateType` (`UpdateType.UPDATE` merges the new fields into the matched record, `UpdateType.REPLACE` replaces it).

```swift
// Non-PCI records
let nonPCIRecords = Skyflow.AdditionalFields(records: [
    Skyflow.AdditionalFieldsRecord(tableName: "persons", data: ["gender": "MALE"], skyflowId: "value")
])
// Upsert
let upsertOptions = [Skyflow.UpsertOption(tableName: "cards", uniqueColumns: ["cardNumber"], updateType: .UPDATE)]
// Send the non-PCI records as additionalFields of CollectOptions (optional) and apply upsert using `upsert` field of CollectOptions (optional)

let options = Skyflow.CollectOptions(additionalFields: nonPCIRecords)
 
let insertCallback = Skyflow.CollectCallback(
    onSuccess: { (response: Skyflow.CollectResponse) in
        for record in response.records {
            if let error = record.error {
                print("failed:", error, "httpCode:", record.httpCode)
            } else {
                print("success:", record)
            }
        }
    },
    onFailure: { (skyflowError: Skyflow.SkyflowError) in
        print(skyflowError.httpCode, skyflowError.message, skyflowError.grpcCode ?? "", skyflowError.httpStatus ?? "", skyflowError.details ?? "")
    }
)
container?.collect(callback: insertCallback, options: options)
```

**Note:** `skyflowId` is required if you want to update the data. If `skyflowId` isn't specified, the `collect(options?)` method creates a new record in the vault.

#### Full-row overwrite with `.REPLACE`
`UpdateType.UPDATE` (used above) only merges the fields present in this request into the matched record - every other column on that record is left untouched. `UpdateType.REPLACE` instead overwrites the entire matched record: any column not included in this request's fields/`additionalFields` is cleared, not just left alone. Use `.REPLACE` when a stale value from a previous update can't be allowed to survive - for example, resetting a record to exactly what this request contains rather than layering it on top of whatever's already there.

```swift
// Mounted element - its collected value becomes part of the replaced row, same as any
// other collect element.
let cardNumberInput = Skyflow.CollectElementInput(tableName: "cards", column: "cardNumber", type: Skyflow.ElementType.CARD_NUMBER)

let cardNumberElement = container?.create(input: cardNumberInput)

// REPLACE example: the matched "cards" record ends up with exactly cardNumber (from the element above) + cvv (from additionalFields) - any other column that record had before (e.g. a stale "expiry_date") is cleared.
let nonPCIRecords = Skyflow.AdditionalFields(records: [
    Skyflow.AdditionalFieldsRecord(tableName: "cards", data: ["cvv": "123"])
])
let replaceUpsertOptions = [Skyflow.UpsertOption(tableName: "cards", uniqueColumns: ["cardNumber"], updateType: .REPLACE)]

let replaceOptions = Skyflow.CollectOptions(additionalFields: nonPCIRecords, upsert: replaceUpsertOptions)

container?.collect(callback: insertCallback, options: replaceOptions)
```

### End to end example of updating data with Skyflow Elements
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
    tableName: "cards",
    column: "cardNumber",
    inputStyles: inputStyles,
    labelStyles: labelStyles,
    errorTextStyles: errorTextStyles,
    iconStyles: iconStyles,
    label: "card number",
    placeholder: "card number",
    type: Skyflow.ElementType.CARD_NUMBER,
    skyflowId: "431eaa6c-5c15-4513-aa15-29f50babe882"
)
 
// Create an option to require the element.
let requiredOption = Skyflow.CollectElementOptions(required: true, enableCopy: true) 
 
// Create a Collect Element from the Collect Container.
let skyflowElement = container?.create(input: input, options: requiredOption)
 
// Can interact with this object as a normal UIView Object and add to View
 
// Non-PCI records
let nonPCIRecords = Skyflow.AdditionalFields(records: [
    Skyflow.AdditionalFieldsRecord(tableName: "persons", data: ["gender": "MALE"]),
    Skyflow.AdditionalFieldsRecord(tableName: "cards", data: ["first_name": "Joe"], skyflowId: "431eaa6c-5c15-4513-aa15-29f50babe882")
])
 
 //Upsert options
 let upsertOptions = [Skyflow.UpsertOption(tableName: "cards", uniqueColumns: ["cardNumber"], updateType: .UPDATE)]
 
// Send the Non-PCI records as additionalFields of CollectOptions (optional) and apply upsert using optional field `upsert` of CollectOptions.
let collectOptions = Skyflow.CollectOptions(additionalFields: nonPCIRecords, upsert: upsertOptions) 
 
 
// Initialize a Skyflow.CollectCallback - required by CollectContainer's collect(callback:options:).
// See "If the entire request fails" above for how onFailure surfaces a typed Skyflow.SkyflowError.
let insertCallback = Skyflow.CollectCallback(
    onSuccess: { (response: Skyflow.CollectResponse) in
        for record in response.records {
            if let error = record.error {
                print("failed:", error, "httpCode:", record.httpCode)
            } else {
                print("success:", record)
            }
        }
    },
    onFailure: { (skyflowError: Skyflow.SkyflowError) in
        print(skyflowError.httpCode, skyflowError.message, skyflowError.grpcCode ?? "", skyflowError.httpStatus ?? "", skyflowError.details ?? "")
    }
)
 
// Call collect method on CollectContainer.
container?.collect(callback: insertCallback, options: collectOptions)
```
 

#### Skyflow returns tokens for the record you just updated:
```json
{
    "records": [
        {
            "tableName": "persons",
            "skyflowId": "77dc3caf-c452-49e1-8625-07219d7567bf",
            "tokens": {
                "gender": [{"token": "12f670af-6c7d-4837-83fb-30365fbc0b1e", "tokenGroupName": "deterministic_string"}]
            },
            "httpCode": 200
        },
        {
            "tableName": "cards",
            "skyflowId": "431eaa6c-5c15-4513-aa15-29f50babe882",
            "tokens": {
                "cardNumber": [{"token": "f3907186-e7e2-466f-91e5-48e12c2bcbc1", "tokenGroupName": "deterministic_string"}],
                "first_name": [{"token": "131e70dc-6f76-4319-bdd3-96281e051051", "tokenGroupName": "deterministic_string"}]
            },
            "httpCode": 200
        }
    ]
}
```
**Note:** See the [Error Handling Reference](#error-handling-reference) for how successful and failed records are distinguished in this array, and how whole-request failures are shaped.

#### Sample partial error response:
```json
{
    "records": [
        {
            "tableName": "cards",
            "skyflowId": "431eaa6c-5c15-4513-aa15-29f50babe882",
            "tokens": {
                "cardNumber": [{"token": "f3907186-e7e2-466f-91e5-48e12c2bcbc1", "tokenGroupName": "deterministic_string"}]
            },
            "httpCode": 200
        },
        {
            "error": "Update failed. skyflow_ids [77dc3caf-c452-49e1-8625-07219d7567bf] are invalid. Specify valid Skyflow IDs.",
            "skyflowId": null,
            "tableName": "",
            "httpCode": 400
        }
    ]
}
```

#### If the entire request fails
See the [Error Handling Reference](#error-handling-reference) for the whole-request `Skyflow.SkyflowError` shape and how to read its properties.

## Validations
 
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
 
## Event Listener on Collect Elements
Helps to communicate with skyflow elements by listening to an event
 
```swift
element!.on(eventName: Skyflow.EventName) { _ in
    // handle function
}
```
 
4 of `Skyflow.EventName`'s events apply to an individual Element's `.on(eventName:)` listener:
- `CHANGE`  
  Change event is triggered when the Element's value changes.
- `READY`   
   Ready event is triggered when the Element is fully rendered
- `FOCUS`   
 Focus event is triggered when the Element gains focus
- `BLUR`    
  Blur event is triggered when the Element loses focus.

`Skyflow.EventName` has a 5th case, `SUBMIT`, but it's a no-op on an individual Element's `.on(eventName:)` - it only fires on a Composable **container's** `.on(eventName:)`, see [Set an event listener on a composable container](#set-an-event-listener-on-a-composable-container).

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
    tableName: "cards",
    column: "cardNumber",
    type: Skyflow.ElementType.CARD_NUMBER,
    )
let cardHolderNameInput = Skyflow.CollectElementInput(
    tableName: "cards",
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
## UI Error for Collect Elements
 
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
    tableName: "cards",
    column: "cardNumber",
    type: Skyflow.ElementType.CARD_NUMBER
)

let cardNumber = container.create(input: cardNumberInput)

// Set custom error
cardNumber.setError("custom error")

// Reset custom error
cardNumber.resetError()
```
 
## Set and Clear value for Collect Elements (DEV ENV ONLY)
 
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
    tableName: "cards",
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
- [Using Skyflow Composable Elements to collect data](#using-skyflow-composable-elements-to-collect-data)
- [Using Skyflow Composable Elements to update data](#using-skyflow-composable-elements-to-update-data)

## When to use Composable vs. Basic Elements
Use **Composable Elements** when you want multiple fields laid out together in a shared row - for example, expiration month and year, or expiration date and CVV, side by side in the same visual container. Use **Basic Elements** (the [section above](#securely-collecting-data-client-side)) when each field is its own standalone view that you place and style individually.

Beyond layout, the two are functionally the same: `CollectElementInput`, `CollectElementOptions`, `collect()`, and `Skyflow.CollectOptions` (`additionalFields`, `upsert`) all work identically for both. Composable Elements just add a `ContainerOptions.layout` array to group elements into rows, plus a `getComposableView()` call to mount the whole group at once instead of mounting each element separately.

## Using Skyflow Composable Elements to collect data
Composable Elements combine multiple Skyflow Elements in a single row. The following steps create a composable element and securely collect data through it.

### Step 1: Create a composable container

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
Composable Elements use the same `Skyflow.CollectElementInput` and `Skyflow.CollectElementOptions` schema as [basic Collect Elements](#step-2-create-a-collect-element) - see that section for the full parameter list, the `Styles`/`Style` walkthrough, and `CollectElementOptions` (including `cardMetaData`/`Skyflow.CardType` and the `format`/`translation` tables).

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

Once the `Skyflow.CollectElementInput` and `Skyflow.CollectElementOptions` objects are defined, add to the container using the ```create(input: CollectElementInput, options: CollectElementOptions)``` method as shown below:
 
```swift
let composableElementInput = Skyflow.CollectElementInput(
    tableName: "cards",
    column: "cardNumber",
    type: Skyflow.ElementType.CARD_NUMBER
)

let collectElementOptions = Skyflow.CollectElementOptions(required: true)

let element = container?.create(input: composableElementInput, options: collectElementOptions)
```
### Step 3: Mount Elements to the Screen

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
### Step 4: Collect data from elements
When you submit the form, call the `collect(callback: Skyflow.CollectCallback, options: Skyflow.CollectOptions? = Skyflow.CollectOptions())` method on the container object. 
The options parameter takes a `Skyflow.CollectOptions` object as shown below:

- `additionalFields`: A `Skyflow.AdditionalFields` object - non-PCI records to insert into the vault alongside whatever's collected from the mounted elements.
- `upsert`: An array of `Skyflow.UpsertOption` objects to support upsert while collecting data from Skyflow elements. Each option specifies the `tableName`, the `uniqueColumns` used to match existing records, and an optional `updateType` (`UpdateType.UPDATE` merges the new fields into the matched record, `UpdateType.REPLACE` replaces it - see [Full-row overwrite with `.REPLACE`](#full-row-overwrite-with-replace) for a worked example).

```swift
// Non-PCI records
let nonPCIRecords = Skyflow.AdditionalFields(records: [
    Skyflow.AdditionalFieldsRecord(tableName: "persons", data: ["gender": "MALE"])
])
// Upsert
let upsertOptions = [Skyflow.UpsertOption(tableName: "cards", uniqueColumns: ["cardNumber"], updateType: .UPDATE)]
// Send the non-PCI records as additionalFields of CollectOptions (optional) and apply upsert using `upsert` field of CollectOptions (optional)

let options = Skyflow.CollectOptions(additionalFields: nonPCIRecords, upsert: upsertOptions)
 
let insertCallback = Skyflow.CollectCallback(
    onSuccess: { (response: Skyflow.CollectResponse) in
        for record in response.records {
            if let error = record.error {
                print("failed:", error, "httpCode:", record.httpCode)
            } else {
                print("success:", record)
            }
        }
    },
    onFailure: { (skyflowError: Skyflow.SkyflowError) in
        print(skyflowError.httpCode, skyflowError.message, skyflowError.grpcCode ?? "", skyflowError.httpStatus ?? "", skyflowError.details ?? "")
    }
)
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
    tableName: "cards",
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
    tableName: "cards",
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
    tableName: "cards",
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
let nonPCIRecords = Skyflow.AdditionalFields(records: [
    Skyflow.AdditionalFieldsRecord(tableName: "persons", data: ["gender": "MALE"])
])
 
 //Upsert options
let upsertOptions = [Skyflow.UpsertOption(tableName: "cards", uniqueColumns: ["cardNumber"], updateType: .UPDATE)]
 
// Send the Non-PCI records as additionalFields of CollectOptions (optional) and apply upsert using optional field `upsert` of CollectOptions.
let collectOptions = Skyflow.CollectOptions(additionalFields: nonPCIRecords, upsert: upsertOptions) 
 
 
// Initialize a Skyflow.CollectCallback - required by CollectContainer's collect(callback:options:).
let insertCallback = Skyflow.CollectCallback(
    onSuccess: { (response: Skyflow.CollectResponse) in
        for record in response.records {
            if let error = record.error {
                print("failed:", error, "httpCode:", record.httpCode)
            } else {
                print("success:", record)
            }
        }
    },
    onFailure: { (skyflowError: Skyflow.SkyflowError) in
        print(skyflowError.httpCode, skyflowError.message, skyflowError.grpcCode ?? "", skyflowError.httpStatus ?? "", skyflowError.details ?? "")
    }
)
 
// Call collect method on CollectContainer.
container?.collect(callback: insertCallback, options: collectOptions)
```
### Sample Response:

```json
{
    "records": [
        {
            "tableName": "cards",
            "skyflowId": "f1714ef8-8deb-489a-a18d-77e0e007f403",
            "tokens": {
                "cardNumber": [{"token": "f3907186-e7e2-466f-91e5-48e12c2bcbc1", "tokenGroupName": "deterministic_string"}]
            },
            "httpCode": 200
        },
        {
            "tableName": "persons",
            "skyflowId": "77dc3caf-c452-49e1-8625-07219d7567bf",
            "tokens": {
                "gender": [{"token": "12f670af-6c7d-4837-83fb-30365fbc0b1e", "tokenGroupName": "deterministic_string"}]
            },
            "httpCode": 200
        }
    ]
}
```
**Note:** See the [Error Handling Reference](#error-handling-reference) for how successful and failed records are distinguished in this array, and how whole-request failures are shaped.

#### Sample partial error response:
```json
{
    "records": [
        {
            "tableName": "cards",
            "skyflowId": "f1714ef8-8deb-489a-a18d-77e0e007f403",
            "tokens": {
                "cardNumber": [{"token": "f3907186-e7e2-466f-91e5-48e12c2bcbc1", "tokenGroupName": "deterministic_string"}]
            },
            "httpCode": 200
        },
        {
            "error": "Invalid request. Table name table not present for record. Specify a valid table name.",
            "skyflowId": null,
            "tableName": "",
            "httpCode": 400
        }
    ]
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

4 of `Skyflow.EventName`'s events apply to an individual Element's `.on(eventName:)` listener:

- CHANGE: Triggered when the Element's value changes.
- READY: Triggered when the Element is fully rendered.
- FOCUS: Triggered when the Element gains focus.
- BLUR: Triggered when the Element loses focus.

`Skyflow.EventName` has a 5th case, `SUBMIT`, but it's a no-op on an individual Element's `.on(eventName:)` - it only fires on a Composable **container's** `.on(eventName:)`, see [Set an event listener on a composable container](#set-an-event-listener-on-a-composable-container) below.

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
    tableName: "cards",
    column: "cardNumber",
    type: Skyflow.ElementType.CARD_NUMBER,
    )
let cardHolderNameInput = Skyflow.CollectElementInput(
    tableName: "cards",
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
    tableName: String,                   // optional the table this data belongs to
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

**Note:** `altText` above is a no-op, same as on `CollectElementInput` - see [Step 2: Create a collect Element](#step-2-create-a-collect-element) for why, and what to use instead.

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
    tableName: "cards",
    column: "cardNumber",
    type: Skyflow.ElementType.CARD_NUMBER,
    )
let cardHolderNameInput = Skyflow.CollectElementInput(
    tableName: "cards",
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
    tableName: "cards",
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
    validations: ValidationSet(rules: [lengthRule])
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
    tableName: "cards",
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
    print("Submit Event Listener is being Triggered.")
}

```

## Using Skyflow Composable Elements to update data
Updating with Composable Elements uses the exact same container setup, `CollectElementInput`, `CollectElementOptions`, and mounting as [collecting data with Composable Elements](#using-skyflow-composable-elements-to-collect-data) - see that section for the full walkthrough. The only difference for an update: pass `skyflowId` when constructing `CollectElementInput` to target an existing record instead of creating a new one.

```swift
let composableElementInput = Skyflow.CollectElementInput(
    tableName: "cards",
    column: "cardNumber",
    type: Skyflow.ElementType.CARD_NUMBER,
    skyflowId: "431eaa6c-5c15-4513-aa15-29f50babe882" // targets an existing record for update instead of creating a new one
)
let element = container?.create(input: composableElementInput)
```

### Update data from Elements 
When you submit the form, call the `collect(callback: Skyflow.CollectCallback, options: Skyflow.CollectOptions? = Skyflow.CollectOptions())` method on the container object. 
The options parameter takes a `Skyflow.CollectOptions` object as shown below:

- `additionalFields`: A `Skyflow.AdditionalFields` object - non-PCI records to insert into the vault alongside whatever's collected from the mounted elements.
- `upsert`: An array of `Skyflow.UpsertOption` objects to support upsert while collecting data from Skyflow elements. Each option specifies the `tableName`, the `uniqueColumns` used to match existing records, and an optional `updateType` (`UpdateType.UPDATE` merges the new fields into the matched record, `UpdateType.REPLACE` replaces it - see [Full-row overwrite with `.REPLACE`](#full-row-overwrite-with-replace) for a worked example).

```swift
// Non-PCI records
let nonPCIRecords = Skyflow.AdditionalFields(records: [
    Skyflow.AdditionalFieldsRecord(tableName: "persons", data: ["gender": "MALE"])
])
// Upsert
let upsertOptions = [Skyflow.UpsertOption(tableName: "cards", uniqueColumns: ["cardNumber"], updateType: .UPDATE)]
// Send the non-PCI records as additionalFields of CollectOptions (optional) and apply upsert using `upsert` field of CollectOptions (optional)

let options = Skyflow.CollectOptions(additionalFields: nonPCIRecords, upsert: upsertOptions)
 
let insertCallback = Skyflow.CollectCallback(
    onSuccess: { (response: Skyflow.CollectResponse) in
        for record in response.records {
            if let error = record.error {
                print("failed:", error, "httpCode:", record.httpCode)
            } else {
                print("success:", record)
            }
        }
    },
    onFailure: { (skyflowError: Skyflow.SkyflowError) in
        print(skyflowError.httpCode, skyflowError.message, skyflowError.grpcCode ?? "", skyflowError.httpStatus ?? "", skyflowError.details ?? "")
    }
)
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
    tableName: "cards",
    column: "first_name",
    inputStyles: inputStyles,
    labelStyles: labelStyles,
    errorTextStyles: errorTextStyles,
    label: "first name",
    placeholder: "first name",
    type: Skyflow.ElementType.CARDHOLDER_NAME,
    skyflowId: "431eaa6c-5c15-4513-aa15-29f50babe882"
)
// Create an option to require the element.
let requiredOption = Skyflow.CollectElementOptions(required: true) 

// Create a Composable Element from the Composable Container.
let cardHolderNameElement = container?.create(input: cardHolderNameElementInput, options: requiredOption)
 
 
let cardNumberElementInput = Skyflow.CollectElementInput(
    tableName: "cards",
    column: "cardNumber",
    inputStyles: inputStyles,
    labelStyles: labelStyles,
    errorTextStyles: errorTextStyles,
    label: "card number",
    placeholder: "card number",
    type: Skyflow.ElementType.CARD_NUMBER,
    skyflowId: "431eaa6c-5c15-4513-aa15-29f50babe882"
)
 
let cardNumberElement = container?.create(input: cardNumberElementInput, options: requiredOption)

let cvvElementInput = Skyflow.CollectElementInput(
    tableName: "cards",
    column: "cvv",
    inputStyles: inputStyles,
    labelStyles: labelStyles,
    errorTextStyles: errorTextStyles,
    label: "cvv",
    placeholder: "cvv",
    type: Skyflow.ElementType.CVV,
    skyflowId: "431eaa6c-5c15-4513-aa15-29f50babe882"
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
let nonPCIRecords = Skyflow.AdditionalFields(records: [
    Skyflow.AdditionalFieldsRecord(tableName: "persons", data: ["gender": "MALE"], skyflowId: "77dc3caf-c452-49e1-8625-07219d7567bf")
])
 
 //Upsert options
 let upsertOptions = [Skyflow.UpsertOption(tableName: "cards", uniqueColumns: ["cardNumber"], updateType: .UPDATE)]
 
// Send the Non-PCI records as additionalFields of CollectOptions (optional) and apply upsert using optional field `upsert` of CollectOptions.
let collectOptions = Skyflow.CollectOptions(additionalFields: nonPCIRecords, upsert: upsertOptions) 
 
// Initialize a Skyflow.CollectCallback - required by CollectContainer's collect(callback:options:).
let insertCallback = Skyflow.CollectCallback(
    onSuccess: { (response: Skyflow.CollectResponse) in
        for record in response.records {
            if let error = record.error {
                print("failed:", error, "httpCode:", record.httpCode)
            } else {
                print("success:", record)
            }
        }
    },
    onFailure: { (skyflowError: Skyflow.SkyflowError) in
        print(skyflowError.httpCode, skyflowError.message, skyflowError.grpcCode ?? "", skyflowError.httpStatus ?? "", skyflowError.details ?? "")
    }
)
 
// Call collect method on CollectContainer.
container?.collect(callback: insertCallback, options: collectOptions)
```
### Sample Success Response:
```json
{
    "records": [
        {
            "tableName": "persons",
            "skyflowId": "77dc3caf-c452-49e1-8625-07219d7567bf",
            "tokens": {
                "gender": [{"token": "12f670af-6c7d-4837-83fb-30365fbc0b1e", "tokenGroupName": "deterministic_string"}]
            },
            "httpCode": 200
        },
        {
            "tableName": "cards",
            "skyflowId": "431eaa6c-5c15-4513-aa15-29f50babe882",
            "tokens": {
                "cardNumber": [{"token": "f3907186-e7e2-466f-91e5-48e12c2bcbc1", "tokenGroupName": "deterministic_string"}],
                "first_name": [{"token": "131e70dc-6f76-4319-bdd3-96281e051051", "tokenGroupName": "deterministic_string"}],
                "cvv": [{"token": "098834fe-de99-4fc8-abdf-88c18a28a2cf", "tokenGroupName": "deterministic_string"}]
            },
            "httpCode": 200
        }
    ]
}
```
### Sample Partial Error Response:
See the [Error Handling Reference](#error-handling-reference) for how successful and failed records are distinguished in this array, and how whole-request failures are shaped.
```json
{
    "records": [
        {
            "tableName": "cards",
            "skyflowId": "431eaa6c-5c15-4513-aa15-29f50babe882",
            "tokens": {
                "cardNumber": [{"token": "f3907186-e7e2-466f-91e5-48e12c2bcbc1", "tokenGroupName": "deterministic_string"}],
                "first_name": [{"token": "131e70dc-6f76-4319-bdd3-96281e051051", "tokenGroupName": "deterministic_string"}],
                "cvv": [{"token": "098834fe-de99-4fc8-abdf-88c18a28a2cf", "tokenGroupName": "deterministic_string"}]
            },
            "httpCode": 200
        },
        {
            "error": "Update failed. skyflowIds [77dc3caf-c452-49e1-8625-07219d7567bf] are invalid. Specify valid Skyflow IDs.",
            "skyflowId": null,
            "tableName": "",
            "httpCode": 400
        }
    ]
}
```

If the entire request fails (for example, the vault itself can't be found), `onFailure` receives a single structured `Skyflow.SkyflowError` instead of a `records` array - see the [Error Handling Reference](#error-handling-reference) for that shape.

# Securely revealing data client-side
-  [**Using Skyflow Elements to reveal data**](#using-skyflow-elements-to-reveal-data)
-  [**UI Error for Reveal Elements**](#ui-error-for-reveal-elements)
-  [**Set token for Reveal Elements**](#set-token-for-reveal-elements)
-  [**Set and clear altText for Reveal Elements**](#set-and-clear-alttext-for-reveal-elements)
 
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
    label: "cardNumber",                 // required, label for the element,
    altText: "XXXX XXXX XXXX XXXX",      // optional, string that is shown before reveal, will show token if it is not provided
)
```
`Note`: 
- To apply a redaction to a token group as part of the detokenize call, use `tokenGroupRedactions` on `Skyflow.RevealOptions` (passed to `reveal(callback:options:)`) rather than on the individual `RevealElementInput` - see [Step 4: Reveal data](#step-4-reveal-data). If not provided, the vault-configured default redaction is applied. Supported redaction values are `PLAIN_TEXT`, `MASKED`, `REDACTED` and `DEFAULT`.

 
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
let revealCallback = Skyflow.RevealCallback(
    onSuccess: { (response: Skyflow.RevealResponse) in
        for record in response.records {
            if let error = record.error {
                print("failed:", error, "httpCode:", record.httpCode)
            } else {
                print("revealed:", record)
            }
        }
    },
    onFailure: { (skyflowError: Skyflow.SkyflowError) in
        print(skyflowError.httpCode, skyflowError.message, skyflowError.grpcCode ?? "", skyflowError.httpStatus ?? "", skyflowError.details ?? "")
    }
)
container.reveal(callback: revealCallback)
```

To apply a redaction to one or more token groups as part of the detokenize call, pass `tokenGroupRedactions` via `Skyflow.RevealOptions`:
```swift
let revealOptions = Skyflow.RevealOptions(
    tokenGroupRedactions: [
        Skyflow.TokenGroupRedaction(tokenGroupName: "deterministic_string", redaction: "MASKED")
    ]
)
container.reveal(callback: revealCallback, options: revealOptions)
```
This is a request-level setting - the redaction applies to every token in the named group, not to individual reveal elements.
 
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
    altText: "XXXX XXXX XXXX XXXX"
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

// Initialize a Skyflow.RevealCallback - required by RevealContainer's reveal(callback:options:).
let revealCallback = Skyflow.RevealCallback(
    onSuccess: { (response: Skyflow.RevealResponse) in
        for record in response.records {
            if let error = record.error {
                print("failed:", error, "httpCode:", record.httpCode)
            } else {
                print("revealed:", record)
            }
        }
    },
    onFailure: { (skyflowError: Skyflow.SkyflowError) in
        print(skyflowError.httpCode, skyflowError.message, skyflowError.grpcCode ?? "", skyflowError.httpStatus ?? "", skyflowError.details ?? "")
    }
)

// Optional: apply a redaction to a token group as part of the detokenize call
let revealOptions = Skyflow.RevealOptions(
    tokenGroupRedactions: [
        Skyflow.TokenGroupRedaction(tokenGroupName: "deterministic_string", redaction: "MASKED")
    ]
)

// Call reveal method on RevealContainer
container?.reveal(callback: revealCallback, options: revealOptions)

```
 
#### Sample Response:
```json
{
    "records": [
        {
            "token": "b63ec4e0-bbad-4e43-96e6-6bd50f483f75",
            "tokenGroupName": "deterministic_string",
            "metadata": {
                "skyflowId": "3ac0424e-fe45-43a9-9193-2e6d2913cbd2",
                "tableName": "cards"
            },
            "httpCode": 200
        },
        {
            "token": "89024714-6a26-4256-b9d4-55ad69aa4047",
            "tokenGroupName": "deterministic_string",
            "metadata": {
                "skyflowId": "3ac0424e-fe45-43a9-9193-2e6d2913cbd2",
                "tableName": "cards"
            },
            "httpCode": 200
        }
    ]
}
```

#### Sample Partial Error Response:
Some tokens assigned to the reveal elements get revealed successfully, while others fail and remain unrevealed. See the [Error Handling Reference](#error-handling-reference) for how successful and failed records are distinguished in this array, and how whole-request failures are shaped:
```json
{
    "records": [
        {
            "token": "b63ec4e0-bbad-4e43-96e6-6bd50f483f75",
            "tokenGroupName": "deterministic_string",
            "metadata": {
                "skyflowId": "3ac0424e-fe45-43a9-9193-2e6d2913cbd2",
                "tableName": "cards"
            },
            "httpCode": 200
        },
        {
            "token": "a4b24714-6a26-4256-b9d4-55ad69aa4047",
            "error": "Tokens not found for a4b24714-6a26-4256-b9d4-55ad69aa4047",
            "httpCode": 404
        }
    ]
}
```
 
## Error Handling Reference

Collect and Reveal both share the same two failure shapes. They're described once here rather than repeated at every call site - the Collect/Reveal sections above link back to this section instead of re-explaining it.

### Per-record failures

`collect()`/`reveal()` never split successes and failures into separate arrays or separate callbacks - every record (or token) comes back together in the same `records` array passed to `onSuccess`, each entry carrying its own `httpCode`. A successful entry carries the flow's data field (`tokens` for Collect, `metadata` for Reveal); a failed entry carries `error` instead, and omits the data field entirely. Check for the presence of `error` to tell the two apart - don't rely on `httpCode` alone.

Collect shape:
```json
{
    "records": [
        {
            "tableName": "cards",
            "skyflowId": "f1714ef8-8deb-489a-a18d-77e0e007f403",
            "tokens": {
                "cardNumber": [{"token": "f3907186-e7e2-466f-91e5-48e12c2bcbc1", "tokenGroupName": "deterministic_string"}]
            },
            "httpCode": 200
        },
        {
            "error": "Invalid request. Table name table not present for record. Specify a valid table name.",
            "skyflowId": null,
            "tableName": "",
            "httpCode": 400
        }
    ]
}
```

Reveal shape:
```json
{
    "records": [
        {
            "token": "b63ec4e0-bbad-4e43-96e6-6bd50f483f75",
            "tokenGroupName": "deterministic_string",
            "metadata": {
                "skyflowId": "3ac0424e-fe45-43a9-9193-2e6d2913cbd2",
                "tableName": "cards"
            },
            "httpCode": 200
        },
        {
            "token": "a4b24714-6a26-4256-b9d4-55ad69aa4047",
            "error": "Tokens not found for a4b24714-6a26-4256-b9d4-55ad69aa4047",
            "httpCode": 404
        }
    ]
}
```

`Skyflow.CollectRecord`/`Skyflow.RevealRecord` expose all of the above as typed properties (`tableName`/`skyflowId`/`tokens`/`hashedData`/`httpCode`/`error` and `token`/`tokenGroupName`/`metadata`/`httpCode`/`error` respectively) - you don't need to read the raw dictionary shown above yourself.

### Whole-request failures (`Skyflow.SkyflowError`)

If the *entire* request fails - vault not found, network error, invalid bearer token - or a client-side validation failure occurs (empty `vaultID`, unmounted element, etc.) - `onFailure` is called instead of `onSuccess`, with a single `Skyflow.SkyflowError` rather than a `records` array.

The vault's wire format for a whole-request failure is:
```json
{
    "error": {
        "grpcCode": 5,
        "httpCode": 404,
        "message": "Invalid request. Vault not found for vaultID: sd0ff0b064c04faabd4d392512b2e5. Specify a valid vaultID. - request-id: cb397-8521-42c2-870c-92dbeec",
        "httpStatus": "Not Found",
        "details": []
    }
}
```

`onFailure` never hands you this dictionary as-is - it's always normalized into a `Skyflow.SkyflowError` (an `NSError` subclass) with these same fields exposed as flat properties, not nested under an `error` key:
```swift
onFailure: { (skyflowError: Skyflow.SkyflowError) in
    print(skyflowError.httpCode, skyflowError.message, skyflowError.grpcCode ?? "", skyflowError.httpStatus ?? "", skyflowError.details ?? "")
}
```
`grpcCode`, `httpStatus`, and `details` are only populated for this whole-request-failure shape - they're `nil` for client-side validation failures (empty `vaultID`, unmounted element, missing required field, etc.), which only populate `httpCode` and `message`:
- `httpCode` is a client-assigned code describing the kind of problem (typically `400`, sometimes `404` for a "not found"-shaped issue like an empty records array) - it was never returned by an actual HTTP response, so don't treat it as a real server status.
- `message` is a description prefixed with the SDK name and version, e.g. `"iOS SDK v1.26.0-beta.1 Validation error.'table' key not found in collect element. Specify a valid value for 'table' key."`

In short: if `grpcCode`/`httpStatus`/`details` are all `nil`, you're looking at a client-side validation failure (bad input, caught before any network call) - use `message` to see which check failed. If they're populated, the vault itself rejected or couldn't process the request.

## Reporting a Vulnerability
 
If you discover a potential security issue in this project, please reach out to us at security@skyflow.com. Please do not create public GitHub issues or Pull Requests, as malicious actors could potentially view them.