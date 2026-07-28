/*
 * Copyright (c) 2022 Skyflow
*/

// Options passed internally for FlowDB v2 collect/insert calls

import Foundation

internal struct FlowVaultICOptions {
    var additionalFields: [String: Any]?
    var upsert: [UpsertOption]?
    var callback: Callback?
    var contextOptions: ContextOptions?

    init(additionalFields: [String: Any]? = nil, upsert: [UpsertOption]? = nil, callback: Callback? = nil, contextOptions: ContextOptions? = nil) {
        self.additionalFields = additionalFields
        self.upsert = upsert
        self.callback = callback
        self.contextOptions = contextOptions
    }

    public func validateUpsert() ->  Bool{
        if self.upsert != nil {
            if self.upsert!.count == 0 {
                let errorCode = ErrorCodes.UPSERT_OPTION_CANNOT_BE_EMPTY()
                self.callback!.onFailure(errorCode.getErrorObject(contextOptions: self.contextOptions!))
                return true
            }

            for (index, currUpsertOption) in self.upsert!.enumerated() {
                if currUpsertOption.table == "" {
                    let errorCode = ErrorCodes.TABLE_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(value: "\(index)")
                    self.callback!.onFailure(errorCode.getErrorObject(contextOptions: self.contextOptions!))
                    return true
                }
                if currUpsertOption.uniqueColumns.isEmpty {
                    let errorCode = ErrorCodes.UNIQUE_COLUMNS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(value: "\(index)")
                    self.callback!.onFailure(errorCode.getErrorObject(contextOptions: self.contextOptions!))
                    return true
                }
            }

        }
        return false;
    }
}
