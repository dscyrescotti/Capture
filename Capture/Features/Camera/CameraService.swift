//
//  CameraService.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import Foundation
import AVFoundation

class CameraService: NSObject {
    let photoLibrary: PhotoLibraryService

    // MARK: - Session
    let captureSession: AVCaptureSession
    var sessionQueue: DispatchQueue = DispatchQueue(label: "capture-session", qos: .userInteractive, attributes: .concurrent)
    var isConfigured: Bool = false

    // MARK: - Devices
    private lazy var captureDevices: [AVCaptureDevice] = {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInTrueDepthCamera,
                .builtInDualCamera,
                .builtInDualWideCamera,
                .builtInTripleCamera,
                .builtInWideAngleCamera,
                .builtInUltraWideCamera,
                .builtInLiDARDepthCamera,
                .builtInTelephotoCamera
            ],
            mediaType: .video,
            position: .unspecified
        ).devices
    }()
    lazy var frontCaptureDevices: [AVCaptureDevice] = {
        captureDevices.filter { $0.position == .front }
    }()
    lazy var rearCaptureDevices: [AVCaptureDevice] = {
        captureDevices.filter { $0.position == .back }
    }()
    var captureDevice: AVCaptureDevice?

    // MARK: - Input
    var captureInput: AVCaptureInput?

    // MARK: - Output
    var captureOutput: AVCaptureOutput?
    var isAvailableLivePhoto: Bool {
        guard let captureOutput = captureOutput as? AVCapturePhotoOutput, captureOutput.availablePhotoCodecTypes.contains(.hevc) else {
            return false
        }
        return captureOutput.isLivePhotoCaptureSupported
    }
    private var captureRect: CGRect = .zero

    // MARK: - Preview
    let cameraPreviewLayer: AVCaptureVideoPreviewLayer

    // MARK: - Image
    var photoImageData: Data?

    init(photoLibrary: PhotoLibraryService) {
        self.photoLibrary = photoLibrary
        self.captureSession = AVCaptureSession()
        self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        super.init()
    }

    func startSession() {
        guard isConfigured && !captureSession.isRunning else { return }
        sessionQueue.async { [unowned self] in
            captureSession.startRunning()
        }
    }

    func stopSession() {
        guard isConfigured && captureSession.isRunning else { return }
        sessionQueue.async { [unowned self] in
            captureSession.stopRunning()
        }
    }

    func setCaptureRect(with rect: CGRect) {
        self.captureRect = rect
    }
}

// MARK: - Actions
extension CameraService {
    func capturePhoto(enablesLivePhoto: Bool = true) {
        guard let captureOutput = captureOutput as? AVCapturePhotoOutput else { return }
        let captureSettings: AVCapturePhotoSettings
        captureOutput.isLivePhotoCaptureEnabled = isAvailableLivePhoto && enablesLivePhoto
        if captureOutput.isLivePhotoCaptureEnabled {
            captureSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            captureSettings.livePhotoMovieFileURL = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString).appendingPathExtension("mov")
        } else {
            captureSettings = AVCapturePhotoSettings()
        }
        captureOutput.capturePhoto(with: captureSettings, delegate: self)
    }
}

// MARK: - Configuration
extension CameraService {
    func configureSession() async throws -> (CameraMode, Bool) {
        try await withCheckedThrowingContinuation { [unowned self] (continuation: CheckedContinuation<(CameraMode, Bool), Error>) in
            sessionQueue.async { [unowned self] in
                captureSession.sessionPreset = .photo
                if captureDevices.isEmpty {
                    continuation.resume(throwing: CameraError.cameraUnavalible)
                }
                var cameraMode: CameraMode = .none
                do {
                    if !rearCaptureDevices.isEmpty {
                        cameraMode = try configureCameraInput(from: rearCaptureDevices, for: .rear)
                    } else if !frontCaptureDevices.isEmpty {
                        cameraMode = try configureCameraInput(from: frontCaptureDevices, for: .front)
                    }
                    try configureCameraOutput()
                } catch {
                    continuation.resume(throwing: error)
                }
                updateConfiguration { [unowned self] in
                    captureSession.beginConfiguration()
                    if let captureInput {
                        captureSession.addInput(captureInput)
                    }
                    if let captureOutput {
                        captureSession.addOutput(captureOutput)
                    }
                    captureSession.commitConfiguration()
                }
                startSession()
                continuation.resume(returning: (cameraMode, isAvailableLivePhoto))
            }
        }
    }

    @discardableResult
    private func configureCameraInput(from devices: [AVCaptureDevice], for cameraMode: CameraMode, at index: Int = 0) throws -> CameraMode {
        guard index < devices.count else { throw CameraError.unknownError }
        captureDevice = devices[index]
        guard let captureDevice else {
            throw CameraError.unknownError
        }
        if let captureInput {
            updateConfiguration { [unowned self] in
                captureSession.beginConfiguration()
                captureSession.removeInput(captureInput)
                captureSession.commitConfiguration()
            }
        }
        let newCaptureInput = try AVCaptureDeviceInput(device: captureDevice)
        guard captureSession.canAddInput(newCaptureInput) else {
            throw CameraError.unknownError
        }
        self.captureInput = newCaptureInput
        return cameraMode
    }

    private func configureCameraOutput() throws {
        let captureOutput = AVCapturePhotoOutput()
        captureOutput.isLivePhotoAutoTrimmingEnabled = false
        guard captureSession.canAddOutput(captureOutput) else {
            throw CameraError.unknownError
        }
        self.captureOutput = captureOutput
    }
}

// MARK: - Camera Switching
extension CameraService {
    func switchCameraDevice(to index: Int, for captureMode: CameraMode) async throws -> (CameraMode, Bool) {
        try await withCheckedThrowingContinuation {  [unowned self] (continuation: CheckedContinuation<(CameraMode, Bool), Error>) in
            sessionQueue.async { [unowned self] in
                var cameraMode: CameraMode = .none
                do {
                    switch captureMode {
                    case .front:
                        cameraMode = try configureCameraInput(from: frontCaptureDevices, for: captureMode, at: index)
                    case .rear:
                        cameraMode = try configureCameraInput(from: rearCaptureDevices, for: captureMode, at: index)
                    case .none:
                        cameraMode = .none
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
                if let captureInput {
                    updateConfiguration { [unowned self] in
                        captureSession.beginConfiguration()
                            captureSession.addInput(captureInput)
                        captureSession.commitConfiguration()
                    }
                }
                continuation.resume(returning: (cameraMode, isAvailableLivePhoto))
            }
        }
    }

    private func updateConfiguration(_ execute: @escaping () -> Void) {
        isConfigured = false
        execute()
        isConfigured = true
    }
}

// MARK: - Permission
extension CameraService {
    var cameraPermissionStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestCameraPermission() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("[Capture]: will begin processing photo - \(resolvedSettings.uniqueID)")
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("[Capture]: finished processing photo - \(photo.resolvedSettings.uniqueID)")
        if let error {
            print("[ERROR]: \(error.localizedDescription)")
            return
        }
        self.photoImageData = photo.fileDataRepresentation()
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        print("[Capture]: finished processing live photo - \(resolvedSettings.uniqueID)")
        if let error {
            print("[Error]: \(error.localizedDescription)")
            return
        }
        guard let photoImageData else {
            return
        }
        print("[URL]: \(outputFileURL.absoluteString)")
        Task {
            do {
                try await photoLibrary.savePhoto(for: photoImageData, withLivePhotoURL: outputFileURL)
            } catch {
                print("[Error]: \(error.localizedDescription)")
            }
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        print("[Capture]: finished capturing - \(resolvedSettings.uniqueID)")
    }
}
