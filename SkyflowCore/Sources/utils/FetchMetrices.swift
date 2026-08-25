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
    
    package func getDeviceDetails(sdkName: String) -> [String: Any] {
        var deviceDetails: [String: Any] = [:]
        do {
            let currentDevice = UIDevice.current

            deviceDetails["device"] = currentDevice.name

            let systemName = currentDevice.systemName
            let systemVersion = currentDevice.systemVersion

            deviceDetails["os_details"] = systemName + "@" + systemVersion
            deviceDetails["sdk_name_version"] = sdkName + "@" + SDK_VERSION
        } catch {
            deviceDetails["device"] = ""
            deviceDetails["os_details"] = ""
            deviceDetails["sdk_name_version"] = ""
        }
        return deviceDetails
    }


    package func getMetrices(sdkName: String) -> [String: Any]{
        let details = getDeviceDetails(sdkName: sdkName)
        let deviceDetails = [
            "sdk_name_version": details["sdk_name_version"] ,
            "sdk_client_device_model": details["device"],
            "sdk_client_os_details": details["os_details"],
        ]
        return deviceDetails as [String : Any]
    }

    // Serialized device metrics for the "sky-metadata" request header - shared by every
    // networking callback in both SDKs, which otherwise each repeated this same
    // serialize-or-fall-back-to-empty-string boilerplate independently.
    package func buildMetadataHeaderValue(sdkName: String) -> String {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: getMetrices(sdkName: sdkName), options: []) else {
            return ""
        }
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
}
