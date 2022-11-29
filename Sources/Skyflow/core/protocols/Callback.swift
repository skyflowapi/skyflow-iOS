/*
 * Copyright (c) 2022 Skyflow
 */

public protocol Callback {
    func onSuccess(_ responseBody: Any)
    func onFailure(_ error: Any)
}
