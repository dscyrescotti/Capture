//
//  CameraView+Alert.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import SwiftUI

extension CameraView {
    @ViewBuilder
    func alertActions(for error: CameraError, completion: @escaping () -> Void) -> some View {
        switch error {
        case .cameraDenied:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Button("Open Settings") {
                    UIApplication.shared.open(url)
                    completion()
                }
                .fontWeight(.bold)
            }
        default:
            EmptyView()
        }
        Button("Cancel", role: .cancel) {
            completion()
        }
    }
}
