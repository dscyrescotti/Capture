//
//  CameraViewModel.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import Core
import SwiftUI
import Utility
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
    @Published var zoomFactor: CGFloat = 1.0
    @Published var photos: Set<CapturePhoto> = []
    @Published var lastZoomFactor: CGFloat = 1.0
    @Published var enablesLivePhoto: Bool = true
    @Published var cameraMode: CameraMode = .none
    @Published var hidesCameraPreview: Bool = true
    @Published var pointOfInterest: CGPoint = .zero
    @Published var isAvailableLivePhoto: Bool = false
    @Published var isAvailableFlashLight: Bool = false
    @Published var photoLibraryError: PhotoLibraryError?
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var focusMode: AVCaptureDevice.FocusMode? = nil
    @Published var exposureMode: AVCaptureDevice.ExposureMode? = nil
    @Published var cameraPermission: AVAuthorizationStatus = .notDetermined

    var camera: CameraService { dependency.camera }
    var photoLibrary: PhotoLibraryService { dependency.photoLibrary }

    init(dependency: CameraDependency) {
        self.dependency = dependency
        self.rearDevices = camera.rearCaptureDevices.map(\.deviceType.deviceName)
        self.frontDevices = camera.frontCaptureDevices.map(\.deviceType.deviceName)
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
        Task {
            do {
                let cameraMode = try await camera.switchCameraDevice(to: index, for: cameraMode)
                await MainActor.run {
                    updateState(cameraMode)
                }
            } catch {
                await MainActor.run {
                    self.cameraError = error as? CameraError ?? .unknownError
                }
            }
        }
    }

    func toggleLivePhoto() {
        if isAvailableLivePhoto {
            enablesLivePhoto.toggle()
        }
    }

    func switchFlashMode() {
        if isAvailableFlashLight {
            switch flashMode {
            case .off: flashMode = .auto
            case .auto: flashMode = .on
            case .on: flashMode = .off
            @unknown default:
                flashMode = .off
            }
        }
    }

    func switchFocusMode() {
        Task {
            let newFocusMode: AVCaptureDevice.FocusMode
            let modes: [AVCaptureDevice.FocusMode] = [.autoFocus, .continuousAutoFocus, .locked].filter {
                if $0 == focusMode {
                    return false
                }
                return camera.isFocusModeSupported($0)
            }
            if modes.isEmpty {
                await MainActor.run {
                    cameraError = .unknownError
                }
                return
            }
            switch focusMode {
            case .autoFocus:
                newFocusMode = modes.contains(.continuousAutoFocus) ? .continuousAutoFocus : .locked
            case .continuousAutoFocus:
                newFocusMode = modes.contains(.locked) ? .locked : .autoFocus
            case .locked:
                newFocusMode = modes.contains(.autoFocus) ? .autoFocus : .continuousAutoFocus
            default:
                return
            }
            do {
                try await camera.switchFocusMode(to: newFocusMode)
                await MainActor.run {
                    focusMode = newFocusMode
                }
            } catch {
                await MainActor.run {
                    cameraError = error as? CameraError ?? .unknownError
                }
            }
        }
    }

    func switchExposureMode() {
        Task {
            let newExposureMode: AVCaptureDevice.ExposureMode
            let modes: [AVCaptureDevice.ExposureMode] = [.autoExpose, .continuousAutoExposure, .locked].filter {
                if $0 == exposureMode {
                    return false
                }
                return camera.isExposureModeSupported($0)
            }
            if modes.isEmpty {
                await MainActor.run {
                    cameraError = .unknownError
                }
                return
            }
            switch exposureMode {
            case .autoExpose:
                newExposureMode = modes.contains(.continuousAutoExposure) ? .continuousAutoExposure : .locked
            case .continuousAutoExposure:
                newExposureMode = modes.contains(.locked) ? .locked : .autoExpose
            case .locked:
                newExposureMode = modes.contains(.autoExpose) ? .autoExpose : .continuousAutoExposure
            default:
                return
            }
            do {
                try await camera.switchExposureMode(to: newExposureMode)
                await MainActor.run {
                    exposureMode = newExposureMode
                }
            } catch {
                await MainActor.run {
                    cameraError = error as? CameraError ?? .unknownError
                }
            }
        }
    }

    func changePointOfInterest(to point: CGPoint, in frame: CGRect) {
        Task {
            do {
                await MainActor.run {
                    pointOfInterest = .zero
                }
                let offset: CGFloat = 60
                let x = max(offset, min(point.x, frame.maxX - offset))
                let y = max(offset, min(point.y, frame.maxY - offset))
                let point = CGPoint(x: x, y: y)
                await MainActor.run {
                    withAnimation {
                        pointOfInterest = point
                    }
                }
                try await camera.changePointOfInterest(to: point)
            } catch {
                await MainActor.run {
                    cameraError = error as? CameraError ?? .unknownError
                }
            }
        }
    }

    func changeZoomFactor() {
        Task {
            do {
                try await camera.changeZoomFactor(to: zoomFactor)
            } catch {
                await MainActor.run {
                    cameraError = error as? CameraError ?? .unknownError
                }
            }
        }
    }

    func capturePhoto() {
        Task {
            camera.capturePhoto(enablesLivePhoto: enablesLivePhoto, flashMode: flashMode)
        }
    }
}

// MARK: - Capture Events
extension CameraViewModel {
    func bindCaptureChannel() async {
        for await event in camera.captureChannel {
            handleCaptureEvent(event)
        }
    }

    private func handleCaptureEvent(_ event: CaptureEvent) {
        switch event {
        case let .photo(uniqueId, photo):
            Task {
                guard let photo, let image = UIImage(data: photo, scale: 1) else { return }
                await MainActor.run {
                    withAnimation {
                        _ = photos.insert(CapturePhoto(id: uniqueId, image: image))
                    }
                }
            }
        case let .end(uniqueId):
            Task {
                guard let photo = photos.first(where: { uniqueId == $0.id }) else { return }
                try? await Task.sleep(for: .seconds(2))
                await MainActor.run {
                    withAnimation {
                        _ = photos.remove(photo)
                    }
                }
            }
        case let .error(uniqueId, error):
            Task {
                guard let photo = photos.first(where: { uniqueId == $0.id }) else { return }
                await MainActor.run {
                    withAnimation {
                        _ = photos.remove(photo)
                    }
                    cameraError = error as? CameraError ?? .unknownError
                }
            }
        default:
            break
        }
    }
}

// MARK: - UI Update
extension CameraViewModel {
    func hideCameraPreview(_ value: Bool) {
        withAnimation {
            hidesCameraPreview = value
        }
    }

    @MainActor
    func updateState(_ cameraMode: CameraMode) {
        withAnimation {
            self.pointOfInterest = .zero
        }
        self.cameraMode = cameraMode
        self.isAvailableLivePhoto = camera.isAvailableLivePhoto
        self.isAvailableFlashLight = camera.isAvailableFlashLight
        self.focusMode = camera.captureDevice?.focusMode
        self.exposureMode = camera.captureDevice?.exposureMode
        self.zoomFactor = camera.captureDevice?.videoZoomFactor ?? .zero
        self.lastZoomFactor = 1.0
    }
}

// MARK: - Scene Phase
extension CameraViewModel {
    func onChangeScenePhase(to scenePhase: ScenePhase) {
        onChangeScenePhaseForCamera(to: scenePhase)
        onChangeScenePhaseForPhotoLibrary(to: scenePhase)
        self.scenePhase = scenePhase
    }

    private func onChangeScenePhaseForCamera(to scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            let isRunning = camera.captureSession.isRunning
            camera.startSession()
            Task {
                try? await Task.sleep(for: .seconds(isRunning ? 0.4 : 0.6))
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
                    try? await Task.sleep(for: .seconds(0.5))
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
                    let cameraMode = try await camera.configureSession()
                    await MainActor.run {
                        updateState(cameraMode)
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
