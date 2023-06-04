//
//  Utils.swift
//  Aislingeach
//
//  Created by Brad Root on 5/27/23.
//

import Foundation
import UIKit

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
    } else if m > n {
        // reduce larger argument
        return gcdBinaryRecursiveStein((m - n) >> 1, n)
    } else {
        // reduce larger argument
        return gcdBinaryRecursiveStein((n - m) >> 1, m)
    }
}

// Put this piece of code anywhere you like
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension Data {
    func printJson() -> String? {
        do {
            let json = try JSONSerialization.jsonObject(with: self, options: [])
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                return nil
            }
            return jsonString
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil
        }
    }
}

extension Notification.Name {
    static let deletedGeneratedImage = Notification.Name("deletedGeneratedImage")
}

class UIRoundedCornerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        layer.cornerRadius = 10
//        layer.shadowRadius = 10
//        layer.shadowOffset = .zero
//        layer.shadowOpacity = 0.1
//        layer.shouldRasterize = true
//        layer.rasterizationScale = UIScreen.main.scale
    }
}
