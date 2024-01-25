//
//  File.swift
//
//
//  Created by Bharti Sagar on 11/05/23.
//

import Foundation
import UIKit

internal class FetchMetrices {
    
    internal func getDeviceDetails() -> [String: Any] {
        var deviceDetails: [String: Any] = [:]
        do {
            let currentDevice = UIDevice.current

            deviceDetails["device"] = currentDevice.name

            let systemName = currentDevice.systemName
            let systemVersion = currentDevice.systemVersion

            deviceDetails["os_details"] = systemName + "@" + systemVersion
            deviceDetails["sdk_name_version"] = "skyflow-iOS@" + SDK_VERSION
        } catch {
            deviceDetails["device"] = ""
            deviceDetails["os_details"] = ""
            deviceDetails["sdk_name_version"] = ""
        }
        return deviceDetails
    }

    
    internal func getMetrices() -> [String: Any]{
        let details = getDeviceDetails()
        let deviceDetails = [
            "sdk_name_version": details["sdk_name_version"] ,
            "sdk_client_device_model": details["device"],
            "sdk_client_os_details": details["os_details"],
        ]
        return deviceDetails as [String : Any]
    }
}
