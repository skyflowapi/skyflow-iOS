
# Changelog

All notable changes to this project will be documented in this file.

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
