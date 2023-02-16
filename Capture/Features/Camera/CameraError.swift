//
//  CameraError.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import Foundation

enum CameraError: LocalizedError {
    case cameraDenied
    case cameraUnavalible
    case unknownError
}

extension CameraError {
    var errorDescription: String? {
        switch self {
        case .cameraDenied:
            return "Camera Acess Denied"
        case .cameraUnavalible:
            return "Camera Unavailable"
        case .unknownError:
            return "Unknown Error"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .cameraDenied:
            return "You need to allow the camera access to fully capture the moment around you. Go to Settings and enable the camera permission."
        case .cameraUnavalible:
            return "There is no camera avalible on your device. 🥲"
        case .unknownError:
            return "Oops! The unknown error occurs."
        }
    }
}
