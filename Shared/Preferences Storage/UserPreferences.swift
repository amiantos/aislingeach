//
//  UserPreferences.swift
//  Aislingeach
//
//  Created by Brad Root on 5/27/23.
//  Copyright © 2023 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

struct UserPreferences {
    fileprivate enum Key {
        static let apiKey = "apiKey"
        static let ratingKudos = "ratingKudos"
        static let ratingImages = "ratingImages"
    }

    static var standard: UserDefaults {
        let database = UserDefaults.standard
        database.register(defaults: [
            Key.apiKey: "0000000000",
            Key.ratingKudos: 0,
            Key.ratingImages: 0,
        ])

        return database
    }
}

extension UserDefaults {
    var apiKey: String {
        return string(forKey: UserPreferences.Key.apiKey) ?? "0000000000"
    }

    func set(apiKey: String) {
        set(apiKey, for: UserPreferences.Key.apiKey)
    }

    var ratingKudos: Int {
        return integer(forKey: UserPreferences.Key.ratingKudos)
    }

    func add(ratingKudos: Int) {
        set(self.ratingKudos+ratingKudos, for: UserPreferences.Key.ratingKudos)
    }

    var ratingImages: Int {
        return integer(forKey: UserPreferences.Key.ratingImages)
    }

    func add(ratingImages: Int) {
        set(self.ratingImages+ratingImages, for: UserPreferences.Key.ratingImages)
    }
}

private extension UserDefaults {
    func set(_ object: Any?, for key: String) {
        set(object, forKey: key)
        synchronize()
    }
}
