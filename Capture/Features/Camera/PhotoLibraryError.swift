//
//  PhotoLibraryError.swift
//  Capture
//
//  Created by Aye Chan on 2/18/23.
//

import Foundation

enum PhotoLibraryError: LocalizedError {
    case photoLibraryDenied
}

extension PhotoLibraryError {
    var errorDescription: String? {
        switch self {
        case .photoLibraryDenied:
            return "Photo Library Acess Denied"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .photoLibraryDenied:
            return "You need to allow the photo library access to save pictures you captured. Go to Settings and enable the photo library permission."
        }
    }
}
