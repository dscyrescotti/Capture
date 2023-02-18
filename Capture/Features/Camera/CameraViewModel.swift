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
    
    var rearDevices: [String] = []
    var frontDevices: [String] = []

    @Published var rearDeviceIndex: Int = 0
    @Published var cameraError: CameraError?
    @Published var frontDeviceIndex: Int = 0
    @Published var disablesActions: Bool = false
    @Published var cameraMode: CameraMode = .none
    @Published var hidesCameraPreview: Bool = true
    @Published var blursCameraPreview: Bool = false
    @Published var photoLibraryError: PhotoLibraryError?
    @Published var cameraPermission: AVAuthorizationStatus = .notDetermined

    var camera: CameraService { dependency.camera }
    var photoLibrary: PhotoLibraryService { dependency.photoLibrary }

    init(dependency: CameraDependency) {
        self.dependency = dependency
        self.rearDevices = camera.rearCaptureDevices.map(\.deviceType.deviceName)
        self.frontDevices = camera.frontCaptureDevices.map(\.deviceType.deviceName)
    }

    func onChangeScenePhase(to scenePhase: ScenePhase) {
        onChangeScenePhaseForCamera(to: scenePhase)
        onChangeScenePhaseForPhotoLibrary(to: scenePhase)
    }

    func hideCameraPreview(_ value: Bool) {
        withAnimation {
            hidesCameraPreview = value
        }
    }
}

// MARK: - Actions
extension CameraViewModel {
    func switchCameraMode() {
        var index: Int
        var cameraMode: CameraMode
        switch self.cameraMode.opposite {
        case .front:
            index = frontDeviceIndex
            cameraMode = .front
        case .rear:
            index = rearDeviceIndex
            cameraMode = .rear
        case .none:
            return
        }
        switchCameraDevice(to: index, for: cameraMode)
    }

    func switchCameraDevice(to index: Int, for cameraMode: CameraMode) {
        self.disablesActions = true
        withAnimation(.linear(duration: 0.2)) {
            self.blursCameraPreview = true
        }
        Task {
            do {
                let cameraMode = try camera.switchCameraDevice(to: index, for: cameraMode)
                await MainActor.run {
                    self.cameraMode = cameraMode
                    self.disablesActions = false
                    withAnimation(.linear(duration: 0.2)) {
                        self.blursCameraPreview = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.disablesActions = false
                    withAnimation(.linear(duration: 0.2)) {
                        self.blursCameraPreview = false
                    }
                    self.cameraError = error as? CameraError ?? .unknownError
                }
            }
        }
    }
}

// MARK: - Scene Phase
extension CameraViewModel {
    private func onChangeScenePhaseForCamera(to scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            Task {
                camera.startSession()
                try? await Task.sleep(for: .seconds(0.6))
                await MainActor.run {
                    hideCameraPreview(false)
                }
            }
            guard cameraError == .cameraDenied else { return }
            Task {
                await checkCameraPermission()
            }
        case .background:
            camera.stopSession()
            hideCameraPreview(true)
        case .inactive:
            camera.stopSession()
            hideCameraPreview(true)
        default:
            break
        }
    }

    private func onChangeScenePhaseForPhotoLibrary(to scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            Task {
                await checkPhotoLibraryPermission()
            }
        default:
            break
        }
    }
}

// MARK: - Permission
extension CameraViewModel {
    func checkCameraPermission() async {
        let status = camera.cameraPermissionStatus
        await MainActor.run {
            cameraPermission = status
        }
        switch status {
        case .notDetermined:
            _ = await camera.requestCameraPermission()
            await checkCameraPermission()
        case .restricted, .denied:
            await MainActor.run {
                cameraError = .cameraDenied
            }
        case .authorized:
            Task {
                do {
                    let cameraMode = try camera.configureSession()
                    await MainActor.run {
                        self.cameraMode = cameraMode
                    }
                } catch {
                    await MainActor.run {
                        self.cameraError = error as? CameraError ?? .unknownError
                    }
                }
            }
        @unknown default:
            break
        }
    }

    func checkPhotoLibraryPermission() async {
        let status = photoLibrary.photoLibraryPermissionStatus
        switch status {
        case .notDetermined:
            _ = await photoLibrary.requestPhotoLibraryPermission()
            await checkPhotoLibraryPermission()
        case .restricted, .denied, .limited:
            await MainActor.run {
                photoLibraryError = .photoLibraryDenied
            }
        default: break
        }
    }
}
