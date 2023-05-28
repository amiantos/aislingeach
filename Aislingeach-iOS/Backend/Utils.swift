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
