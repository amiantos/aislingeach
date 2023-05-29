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

        switch err {
        case let ErrorResponse.error(code, _, _):
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

extension Encodable {
    func toJSONString() -> String {
        let jsonData = try! JSONEncoder().encode(self)
        return String(data: jsonData, encoding: .utf8)!
    }
}

func instantiate<T: Decodable>(jsonString: String) -> T? {
    return try? JSONDecoder().decode(T.self, from: jsonString.data(using: .utf8)!)
}
