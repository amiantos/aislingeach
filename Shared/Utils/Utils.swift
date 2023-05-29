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

func findEasySolution(_ m: Int, _ n: Int) -> Int? {
    if m == n {
        return m
    }
    if m == 0 {
        return n
    }
    if n == 0 {
        return m
    }
    return nil
}

func gcdBinaryRecursiveStein(_ m: Int, _ n: Int) -> Int {
    if let easySolution = findEasySolution(m, n) { return easySolution }

    if (m & 1) == 0 {
        // m is even
        if (n & 1) == 1 {
            // and n is odd
            return gcdBinaryRecursiveStein(m >> 1, n)
        } else {
            // both m and n are even
            return gcdBinaryRecursiveStein(m >> 1, n >> 1) << 1
        }
    } else if (n & 1) == 0 {
        // m is odd, n is even
        return gcdBinaryRecursiveStein(m, n >> 1)
    } else if (m > n) {
        // reduce larger argument
        return gcdBinaryRecursiveStein((m - n) >> 1, n)
    } else {
        // reduce larger argument
        return gcdBinaryRecursiveStein((n - m) >> 1, m)
    }
}
