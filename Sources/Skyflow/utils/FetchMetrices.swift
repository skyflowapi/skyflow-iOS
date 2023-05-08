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
        let currentDevice = UIDevice.current
        let systemName = currentDevice.systemName
        let deviceName = currentDevice.name
        let systemVersion = currentDevice.systemVersion
        let deviceDetails = [
            "device": deviceName,
            "os_details": systemName + "@" + systemVersion,
            "sdk_name_version": "skyflow-iOS@" + SDK_VERSION
        ]
        return deviceDetails
    }

    
    internal func getMetrices() -> [String: Any]{
        let details = getDeviceDetails()
        let deviceDetails = [
            "sdk_name_version": details["sdk_name_version"] ,
            "sdk_client_device_model": details["device"],
            "sdk_client_os_detail": details["os_details"],
        ]
        return deviceDetails as [String : Any]
    }
}
