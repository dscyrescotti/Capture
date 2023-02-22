//
//  Factory.swift
//  Capture
//
//  Created by Aye Chan on 2/22/23.
//

import SwiftUI

public protocol Factory {
    associatedtype Content: View
    @ViewBuilder
    func contentView() -> Content
}

extension Factory {
    func view() -> AnyView {
        AnyView(contentView())
    }
}
