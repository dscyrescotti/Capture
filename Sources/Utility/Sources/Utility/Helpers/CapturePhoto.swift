//
//  CapturePhoto.swift
//  Capture
//
//  Created by Aye Chan on 2/22/23.
//

import UIKit

public struct CapturePhoto: Identifiable, Hashable, Comparable {
    public static func < (lhs: CapturePhoto, rhs: CapturePhoto) -> Bool {
        lhs.id < rhs.id
    }

    public var id: Int64
    public var image: UIImage

    public init(id: Int64, image: UIImage) {
        self.id = id
        self.image = image
    }
}
