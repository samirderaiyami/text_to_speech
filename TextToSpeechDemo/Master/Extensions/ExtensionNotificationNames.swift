//
//  ExtensionNotificationNames.swift
//  More
//
//  Created by Mindventory on 29/09/21.
//  Copyright © 2022 Appcano LLC. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let FavoriteClick = Notification.Name("FavoriteClick")
    static let PastAffirmationClick = Notification.Name("PastAffirmationClick")
    static let MyOwnAffirmationClick = Notification.Name("MyOwnAffirmationClick")
    static let RemovedPastAffirmations = Notification.Name("RemovedPastAffirmations")
    static let OwnAffirmationsRemoveOrAdd = Notification.Name("OwnAffirmationsRemoveOrAdd")
}
