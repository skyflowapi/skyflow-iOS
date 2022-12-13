/*
 * Copyright (c) 2022 Skyflow
 */

public protocol TokenProvider {
    func getBearerToken(_ apiCallback: Callback)
}
