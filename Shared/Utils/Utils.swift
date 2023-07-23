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
    static let imageDatabaseUpdated = Notification.Name("imageDatabaseUpdated")
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

public extension UIImage {
    /**
     Returns the flat colorized version of the image, or self when something was wrong

     - Parameters:
         - color: The colors to user. By defaut, uses the ``UIColor.white`

     - Returns: the flat colorized version of the image, or the self if something was wrong
     */
    func colorized(with color: UIColor = .white) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)

        defer {
            UIGraphicsEndImageContext()
        }

        guard let context = UIGraphicsGetCurrentContext(), let cgImage = cgImage else { return self }

        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        color.setFill()
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.clip(to: rect, mask: cgImage)
        context.fill(rect)

        guard let colored = UIGraphicsGetImageFromCurrentImageContext() else { return self }

        return colored
    }

    /**
     Returns the stroked version of the fransparent image with the given stroke color and the thickness.

     - Parameters:
         - color: The colors to user. By defaut, uses the ``UIColor.white`
         - thickness: the thickness of the border. Default to `2`
         - quality: The number of degrees (out of 360): the smaller the best, but the slower. Defaults to `10`.

     - Returns: the stroked version of the image, or self if something was wrong
     */

    func stroked(with color: UIColor = .white, thickness: CGFloat = 2, quality: CGFloat = 10) -> UIImage {
        guard let cgImage = cgImage else { return self }

        // Colorize the stroke image to reflect border color
        let strokeImage = colorized(with: color)

        guard let strokeCGImage = strokeImage.cgImage else { return self }

        /// Rendering quality of the stroke
        let step = quality == 0 ? 10 : abs(quality)

        let oldRect = CGRect(x: thickness, y: thickness, width: size.width, height: size.height).integral
        let newSize = CGSize(width: size.width + 2 * thickness, height: size.height + 2 * thickness)
        let translationVector = CGPoint(x: thickness, y: 0)

        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)

        guard let context = UIGraphicsGetCurrentContext() else { return self }

        defer {
            UIGraphicsEndImageContext()
        }
        context.translateBy(x: 0, y: newSize.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.interpolationQuality = .high

        for angle: CGFloat in stride(from: 0, to: 360, by: step) {
            let vector = translationVector.rotated(around: .zero, byDegrees: angle)
            let transform = CGAffineTransform(translationX: vector.x, y: vector.y)

            context.concatenate(transform)

            context.draw(strokeCGImage, in: oldRect)

            let resetTransform = CGAffineTransform(translationX: -vector.x, y: -vector.y)
            context.concatenate(resetTransform)
        }

        context.draw(cgImage, in: oldRect)

        guard let stroked = UIGraphicsGetImageFromCurrentImageContext() else { return self }

        return stroked
    }
}

extension CGPoint {
    /**
     Rotates the point from the center `origin` by `byDegrees` degrees along the Z axis.

     - Parameters:
         - origin: The center of he rotation;
         - byDegrees: Amount of degrees to rotate around the Z axis.

     - Returns: The rotated point.
     */
    func rotated(around origin: CGPoint, byDegrees: CGFloat) -> CGPoint {
        let dx = x - origin.x
        let dy = y - origin.y
        let radius = sqrt(dx * dx + dy * dy)
        let azimuth = atan2(dy, dx) // in radians
        let newAzimuth = azimuth + byDegrees * .pi / 180.0 // to radians
        let x = origin.x + radius * cos(newAzimuth)
        let y = origin.y + radius * sin(newAzimuth)
        return CGPoint(x: x, y: y)
    }
}
