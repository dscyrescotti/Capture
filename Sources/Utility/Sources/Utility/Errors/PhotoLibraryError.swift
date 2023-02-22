//
//  PhotoLibraryError.swift
//  Capture
//
//  Created by Aye Chan on 2/18/23.
//

import Foundation

public enum PhotoLibraryError: LocalizedError {
    case photoNotFound
    case photoSavingFailed
    case photoLibraryDenied
    case unknownError
}

public extension PhotoLibraryError {
    var errorDescription: String? {
        switch self {
        case .photoNotFound:
            return "Photo Not Found"
        case .photoSavingFailed:
            return "Photo Saving Failed"
        case .photoLibraryDenied:
            return "Photo Library Acess Denied"
        case .unknownError:
            return "Unknown Error"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .photoNotFound:
            return "The photo is not found in the photo library."
        case .photoSavingFailed:
            return "Oops! There is an error when saving a photo into the photo library."
        case .photoLibraryDenied:
            return "You need to allow the photo library access to save pictures you captured. Go to Settings and enable the photo library permission."
        case .unknownError:
            return "Oops! The unknown error occurs."
        }
    }
}
