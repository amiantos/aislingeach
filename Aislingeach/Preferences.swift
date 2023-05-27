//
//  Preferences.swift
//  Aislingeach
//
//  Created by Brad Root on 5/27/23.
//  Copyright © 2023 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

struct Preferences {
    fileprivate enum Key {
        static let apiKey = "apiKey"
    }

    static var standard: UserDefaults {
        let database = UserDefaults.standard
        database.register(defaults: [
            Key.apiKey: ""
        ])

        return database
    }
}

extension UserDefaults {
    var apiKey: String {
        return string(forKey: Preferences.Key.apiKey) ?? ""
    }

    func set(apiKey: String) {
        set(apiKey, for: Preferences.Key.apiKey)
    }
}

private extension UserDefaults {
    func set(_ object: Any?, for key: String) {
        set(object, forKey: key)
        synchronize()
    }
}
