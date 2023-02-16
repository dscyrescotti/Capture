//
//  CameraViewModel.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import SwiftUI
import Foundation
import AVFoundation

class CameraViewModel: ObservableObject {
    let dependency: CameraDependency

    @Published var error: CameraError?
    @Published var cameraPermission: AVAuthorizationStatus = .notDetermined

    var camera: CameraService { dependency.camera }

    init(dependency: CameraDependency) {
        self.dependency = dependency
    }

    func onChangeScenePhase(to scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            guard error == .cameraDenied else { return }
            Task {
                await checkCameraPermission()
            }
        default:
            break
        }
    }

    func checkCameraPermission() async {
        let status = dependency.camera.cameraPermissionStatus
        await MainActor.run {
            cameraPermission = status
        }
        switch status {
        case .notDetermined:
            _ = await dependency.camera.requestCameraPermission()
            await checkCameraPermission()
        case .restricted, .denied:
            await MainActor.run {
                error = .cameraDenied
            }
        case .authorized:
            Task {
                do {
                    try dependency.camera.configureSession()
                } catch {
                    await MainActor.run {
                        self.error = error as? CameraError
                    }
                }
            }
        @unknown default:
            break
        }
    }
}
