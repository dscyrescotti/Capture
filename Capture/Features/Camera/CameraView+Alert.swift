//
//  CameraView+Alert.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import SwiftUI

extension CameraView {
    @ViewBuilder
    func cameraAlertActions(for error: CameraError, completion: @escaping () -> Void) -> some View {
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

    @ViewBuilder
    func photoLibraryAlertActions(for error: PhotoLibraryError, completion: @escaping () -> Void) -> some View {
        switch error {
        case .photoLibraryDenied:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Button("Open Settings") {
                    UIApplication.shared.open(url)
                    completion()
                }
                .fontWeight(.bold)
            }
        }
        Button("Cancel", role: .cancel) {
            completion()
        }
    }
}
