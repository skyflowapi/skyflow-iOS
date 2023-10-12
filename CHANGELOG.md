
# Changelog

All notable changes to this project will be documented in this file.

### Added

## [1.20.0] - 2023-10-06
- Ability to customise Copy behaviour for Collect and Reveal Elements.

### Added

## [1.19.0] - 2023-06-23
- Added input formatting for collect and reveal elements

### Added

## [1.18.0] - 2023-06-08

### Added
- Added redaction type in Reveal and detokenize

## [1.17.6] - 2023-03-09

### Fixed
- Removed grace period logic for bearer token generation.

## [1.17.5] - 2023-03-06

### Fixed
- Change listener for expiry month elements

## [1.17.0] - 2022-11-22

### Added
- upsert support while collecting data through skyflow elements.
- upsert support for insert method

## [1.16.4] - 2022-08-02

### Fixed
- long press on reveal elements now triggers copy dialog box

## [1.16.3] - 2022-07-20

### Fixed
- isValid returns false for valid element in listeners

## [1.16.2] - 2022-06-28

### Added
- Copyright header to all files
- Security email in README

## [1.16.1] - 2022-06-21

### Fixed
- Amex BIN value now returns first 6 digits instead of 8

## [1.16.0] - 2022-06-07

### Changed
- Return BIN value for Card Number Collect Elements in prod env

## [1.15.0] - 2022-05-10

### Added
- Support for generic card numbers

### Changed
- Deprecated `invokeConnection()`
- Deprecated `invokeSoapConnection()`


## [1.14.1] - 2022-04-19

### Added
- Add Card icon for empty `CARD_NUMBER` collect element

## [1.14.0] - 2022-04-19

### Added
- `EXPIRATION_YEAR` element type
- `EXPIRATION_MONTH` element type

## [1.13.0] - 2022-04-05

### Added
- Support for application/x-www-form-urlencoded and multipart/form-data content-types in connections.


## [1.12.1] - 2022-03-29

### Added
- Validation to token obtained from `tokenProvider`

### Fixed
- Request headers not getting overriden due to case sensitivity

## [1.12.0] - 2022-02-24

### Added
- Request ID in error logs and error responses for API Errors

## [1.11.1] - 2022-02-08

### Fixed
- SDK crashing on invokeConnection with more than 2 elements `formatRegex` option

## [1.11.0] - 2022-02-08

### Added
- `replaceText` option for `RevealElement`

## [1.10.0] - 2022-01-25

### Fixed
- Resolved App crashing issue with invalid vaultURL in `reveal`

### Added
- `formatRegex` option for `RevealElement`

## [1.9.1] - 2022-01-18

### Fixed
- Fixes in `invokeSoapConnection()` method

## [1.9.0] - 2022-01-11

### Added
- `Soap protocol` support for connections

## [1.8.0] - 2021-12-07

### Added
- `setError(error : String)` method to set custom UI error to be displayed on the collect and reveal Elements
- `resetError()` method is used to clear the custom UI error message set through setError 
- `format` parameter in `collectElementOptions` to support different type of date formats for `EXPIRATION_DATE` element
- `setValue(value: String)` and `clearValue()` method in DEV env, to set/clear the value of a collect element.
- `setToken(value: String)` method to set the token for a reveal element.
- `setAltText(value: String)` and `clearAltText()` method to set/clear the altText for a reveal 

### Changed
- Changed error messages in the logs and callback errors.
- altText support has been deprecated for collect element
- vaultId and vaultURL are now optional parameters in Configuration constructor

### Fixed
- Updating UI error messages

## [1.7.0] - 2021-11-24

### Added
- `validations` option in `CollectElementInput` that takes a set of validation rules
- `RegexMatch`, `LengthMatch` & `ElementValueMatch` Validation rules
- `PIN` element type

### Fixed
- Card Number validation

## [1.6.0] - 2021-11-17


### Added
- `enableCardIcon` option to configure Card Icon visibility
- `INPUT_FIELD` Element type for custom UI elements
- `unmount` method to reset collect element to initial state

### Changed
- New VISA Card Icon with updated Logo

## [1.5.0] - 2021-11-10

### Changed

- Renamed `invokeGateway` to `invokeConnection`
- Renamed `gatewayURL` to `connectionURL`
- Renamed `GatewayConfig` to `ConnectionConfig`

## [1.4.0] - 2021-10-26

### Added

- Detecting card type and displaying icon in the card number element

## [1.3.0] - 2021-10-19

### Added

- `logLevel` option to allow different levels of logging
- event listeners for collect element
- `env` option for accessibility of value in event listeners

### Changed
- Standardized error information for easier debugging.
- deprecated redaction in `detokenize` method and `revealElementInput` initializer.
- change in `detokenize` response format.

## [1.2.0] - 2021-10-05

### Added

- invokeGateway method to work with inbound/outbound integrations using Skyflow Gateway

### Changed
- `table` and `column` are optional in CollectElementInput, when using invokeGateway
- `token` and `redaction` are optional in RevealElementInput, when using invokeGateway

## [1.1.0] - 2021-09-22

### Added

- getById method to reveal fields using SkyflowID's
- support for Non-PCI fields, data can be passed as additional fields in `CollectOptions` of container.collect method.
- `altText` for CollectElement
- `labelStyles` for CollectElement
- `errorTextStyles` for CollectElement
- `altText` for RevealElement
- `labelStyles` for RevealElement
- `errorTextStyles` for RevealElement
- default error message for reveal element

### Changed

- Renamed `styles` to `inputStyles` in CollectElementInput and RevealElementInput.
- Renamed `get` method to `detokenize`.
- Renamed `id` to `token` in request and response of `detokenize` and `container.reveal()`.
- Changed `InsertOptions` to `CollectOptions` in collect method of container.

### Fixed

- Fixed issues in styling.
- Fixed unexpected behaviour on malformed/bad url
