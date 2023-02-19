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
    var scenePhase: ScenePhase = .inactive

    @Published var rearDeviceIndex: Int = 0
    @Published var cameraError: CameraError?
    @Published var frontDeviceIndex: Int = 0
    @Published var enablesLivePhoto: Bool = true
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
        self.scenePhase = scenePhase
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
        withAnimation(.linear(duration: 0.2)) {
            self.blursCameraPreview = true
        }
        Task {
            do {
                let (cameraMode, enablesLivePhoto) = try await camera.switchCameraDevice(to: index, for: cameraMode)
                await MainActor.run {
                    self.cameraMode = cameraMode
                    self.enablesLivePhoto = enablesLivePhoto
                    withAnimation(.linear(duration: 0.2)) {
                        self.blursCameraPreview = false
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation(.linear(duration: 0.2)) {
                        self.blursCameraPreview = false
                    }
                    self.cameraError = error as? CameraError ?? .unknownError
                }
            }
        }
    }

    func toggleLivePhoto() {
        if camera.isAvailableLivePhoto {
            enablesLivePhoto.toggle()
        }
    }

    func capturePhoto() {
        Task {
            camera.capturePhoto(enablesLivePhoto: enablesLivePhoto)
        }
    }
}

// MARK: - Scene Phase
extension CameraViewModel {
    private func onChangeScenePhaseForCamera(to scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            Task {
                try? await Task.sleep(for: .seconds(0.4))
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
            if self.scenePhase == .active {
                camera.stopSession()
                Task {
                    try? await Task.sleep(for: .seconds(0.8))
                    await MainActor.run {
                        hideCameraPreview(true)
                    }
                }
            } else {
                camera.startSession()
            }
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
                    let (cameraMode, isAvailableLivePhoto) = try await camera.configureSession()
                    await MainActor.run {
                        self.cameraMode = cameraMode
                        self.enablesLivePhoto = isAvailableLivePhoto
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
