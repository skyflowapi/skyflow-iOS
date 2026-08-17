//
//  File.swift
//
//
//  Created by Bharti Sagar on 11/05/23.
//

import Foundation
import UIKit

package class FetchMetrices {
    package init() {}
    
    package func getDeviceDetails() -> [String: Any] {
        var deviceDetails: [String: Any] = [:]
        do {
            let currentDevice = UIDevice.current

            deviceDetails["device"] = currentDevice.name

            let systemName = currentDevice.systemName
            let systemVersion = currentDevice.systemVersion

            deviceDetails["os_details"] = systemName + "@" + systemVersion
            deviceDetails["sdk_name_version"] = SDK_NAME + "@" + SDK_VERSION
        } catch {
            deviceDetails["device"] = ""
            deviceDetails["os_details"] = ""
            deviceDetails["sdk_name_version"] = ""
        }
        return deviceDetails
    }

    
    package func getMetrices() -> [String: Any]{
        let details = getDeviceDetails()
        let deviceDetails = [
            "sdk_name_version": details["sdk_name_version"] ,
            "sdk_client_device_model": details["device"],
            "sdk_client_os_details": details["os_details"],
        ]
        return deviceDetails as [String : Any]
    }
}
