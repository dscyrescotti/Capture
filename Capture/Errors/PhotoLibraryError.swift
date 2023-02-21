//
//  PhotoLibraryError.swift
//  Capture
//
//  Created by Aye Chan on 2/18/23.
//

import Foundation

enum PhotoLibraryError: LocalizedError {
    case photoLibraryDenied
    case photoNotFound
}

extension PhotoLibraryError {
    var errorDescription: String? {
        switch self {
        case .photoLibraryDenied:
            return "Photo Library Acess Denied"
        case .photoNotFound:
            return "Photo Not Found"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .photoLibraryDenied:
            return "You need to allow the photo library access to save pictures you captured. Go to Settings and enable the photo library permission."
        case .photoNotFound:
            return "The photo is not found in the photo library."
        }
    }
}
