/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation
import Skyflow

public class ExampleTokenProvider: TokenProvider {
    public func getBearerToken(_ apiCallback: Skyflow.Callback) {
        apiCallback.onSuccess("eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY2MiOiJ3MTYwZWQxNjEyMjk0NmUxYTczYWIxYzU2NTNmYjczNyIsImF1ZCI6Imh0dHBzOi8vbWFuYWdlLnNreWZsb3dhcGlzLXByZXZpZXcuY29tIiwiZXhwIjoxNzczMjIxODY1LCJpYXQiOjE3NzMxMzU0NjUsImlzcyI6InNhLWF1dGhAbWFuYWdlLnNreWZsb3dhcGlzLXByZXZpZXcuY29tIiwianRpIjoidDg3YWY0NmJhYWU1NDEzM2JmMDA2NzkzNGE2OTA5NzIiLCJzdWIiOiJlMjQ4YjcxMzQwMDY0Mjg3ODU4NGZjZjY0YmY3NjU3MiJ9.rEDhb8XBVF2BRGI6TIdNbx2pa386juZrcuxPK12XxgJoh0CKA0uUpRoShhM6FFJaLwc9_rL9wM0SClherkg4bxq4RfECcaDBaCpn78yKipVE7I1FKKPIQIarUhcjCMqJFJas0mvTWz73bCcN1yxSu4N1ao5Sq3pj4rxktQGWt62TsspgpN6FqJyC_snSCMqQIffjh8XZDyVxFYA3_A6-OhgtJqzSIjWpWCUhwD0tDXA9I2mStkeawpvinwcUmynPtCGcjRNIkaruXTZ5SlcSqedlYTLSgzyQKlMVlV-bgVnv1zcJyAgNwQT9ykMh1AQfVeQQZeZK1F_ZkcDbvCNtNw")
//        if let url = URL(string: "<YOUR_TOKEN_PROVIDER_ENDPOINT>") {
//            let session = URLSession(configuration: .default)
//            let task = session.dataTask(with: url) { data, _, error in
//                if error != nil {
//                    print(error!)
//                    return
//                }
//                if let safeData = data {
//                    do {
//                        let x = try JSONSerialization.jsonObject(with: safeData, options: []) as? [String: String]
//                        if let accessToken = x?["accessToken"] {
//                            apiCallback.onSuccess(accessToken)
//                        }
//                    } catch {
//                        print("access token wrong format")
//                    }
//                }
//            }
//            task.resume()
//        }
    }
}
