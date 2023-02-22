//
//  RootSwitcher.swift
//  Capture
//
//  Created by Aye Chan on 2/22/23.
//

import Foundation

public class RootSwitcher: ObservableObject {
    @Published var switchRoute: Route?

    private init() { }

    static let shared = RootSwitcher()

    public static func setInitialRoute(to route: Route) {
        shared.switchRoute = route
    }
}
