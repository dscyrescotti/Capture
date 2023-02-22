//
//  Route.swift
//  Capture
//
//  Created by Aye Chan on 2/22/23.
//

import SwiftUI
import Foundation

public enum Route: Equatable, Identifiable, Hashable {
    case camera
    case gallery

    public var id: Int {
        hashValue
    }
}

extension Route {
    private var factory: any Factory {
        self as! any Factory
    }

    var contentView: AnyView {
        factory.view()
    }
}
