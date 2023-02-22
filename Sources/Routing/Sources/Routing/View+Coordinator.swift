//
//  View+Coordinator.swift
//  Capture
//
//  Created by Aye Chan on 2/22/23.
//

import SwiftUI

public extension View {
    @ViewBuilder
    func coordinated(_ coordinator: Coordinator, onDismiss: (() -> Void)? = nil) -> some View {
        fullScreenCover(item: coordinator.$fullScreenRoute, onDismiss: onDismiss) { route in
            route.contentView
        }
    }
}
