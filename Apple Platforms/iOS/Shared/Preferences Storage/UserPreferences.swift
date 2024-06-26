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
        static let slowWorkers = "slowWorkers"
        static let trustedWorkers = "trustedWorkers"
        static let shareWithLaion = "shareWithLaion"
        static let allowNSFW = "allowNSFW"
        static let recentSettings = "recentSettings"
        static let autoCloseCreatePanel = "autoCloseCreatePanel"
        static let favoriteModels = "favoriteModels"
    }

    static var standard: UserDefaults {
        let database = UserDefaults.standard
        database.register(defaults: [
            Key.apiKey: "0000000000",
            Key.ratingKudos: 0,
            Key.ratingImages: 0,
            Key.slowWorkers: true,
            Key.trustedWorkers: true,
            Key.allowNSFW: false,
            Key.shareWithLaion: true,
            Key.recentSettings: "{}",
            Key.autoCloseCreatePanel: true,
            Key.favoriteModels: [],
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
        set(self.ratingKudos + ratingKudos, for: UserPreferences.Key.ratingKudos)
    }

    var ratingImages: Int {
        return integer(forKey: UserPreferences.Key.ratingImages)
    }

    func add(ratingImages: Int) {
        set(self.ratingImages + ratingImages, for: UserPreferences.Key.ratingImages)
    }

    func set(slowWorkers: Bool) {
        set(slowWorkers, forKey: UserPreferences.Key.slowWorkers)
    }

    var slowWorkers: Bool {
        return bool(forKey: UserPreferences.Key.slowWorkers)
    }

    func set(trustedWorkers: Bool) {
        set(trustedWorkers, forKey: UserPreferences.Key.trustedWorkers)
    }

    var trustedWorkers: Bool {
        return bool(forKey: UserPreferences.Key.trustedWorkers)
    }

    func set(allowNSFW: Bool) {
        set(allowNSFW, forKey: UserPreferences.Key.allowNSFW)
    }

    var allowNSFW: Bool {
        return bool(forKey: UserPreferences.Key.allowNSFW)
    }

    func set(shareWithLaion: Bool) {
        set(shareWithLaion, forKey: UserPreferences.Key.shareWithLaion)
    }

    var shareWithLaion: Bool {
        return bool(forKey: UserPreferences.Key.shareWithLaion)
    }

    func set(autoCloseCreatePanel: Bool) {
        set(autoCloseCreatePanel, forKey: UserPreferences.Key.autoCloseCreatePanel)
    }

    var autoCloseCreatePanel: Bool {
        return bool(forKey: UserPreferences.Key.autoCloseCreatePanel)
    }

    func set(recentSettings: GenerationInputStable) {
        set(recentSettings.toJSONString(), forKey: UserPreferences.Key.recentSettings)
    }

    var recentSettings: GenerationInputStable? {
        guard let string = string(forKey: UserPreferences.Key.recentSettings) else { return nil }
        return try? JSONDecoder().decode(
            GenerationInputStable.self,
            from: string.data(using: .utf8)!
        )
    }

    var favoriteModels: [String] {
        return stringArray(forKey: UserPreferences.Key.favoriteModels) ?? []
    }

    func set(favoriteModels: [String]) {
        set(favoriteModels, forKey: UserPreferences.Key.favoriteModels)
    }

}

private extension UserDefaults {
    func set(_ object: Any?, for key: String) {
        set(object, forKey: key)
        synchronize()
    }
}
