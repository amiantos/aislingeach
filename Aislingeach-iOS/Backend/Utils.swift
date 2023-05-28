//
//  Utils.swift
//  Aislingeach
//
//  Created by Brad Root on 5/27/23.
//

import Foundation

extension Error {

    var code: Int {
        guard let err = self as? ErrorResponse
            else { return (self as NSError).code }

        switch err{
        case ErrorResponse.error(let code, _, _):
            return code
        }
    }
}

func hordeClientAgent() -> String {
    guard let dictionary = Bundle.main.infoDictionary else {
        return ""
    }
    let version = dictionary["CFBundleShortVersionString"] as! String
    let name = dictionary["CFBundleName"] as! String
    return "\(name):\(version):https://github.com/amiantos/aislingeach"
}
