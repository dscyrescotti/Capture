//
//  Application.swift
//  Capture
//
//  Created by Aye Chan on 2/22/23.
//

import Routing
import SwiftUI

public struct Application: View {
    @Coordinator var coordinator

    public init() { }

    public var body: some View {
        RootView($coordinator)
    }

    public static func setInitialRoute(to route: Route) {
        RootSwitcher.setInitialRoute(to: route)
    }
}
