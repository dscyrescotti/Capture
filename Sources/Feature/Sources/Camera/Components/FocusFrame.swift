//
//  FocusFrame.swift
//  Capture
//
//  Created by Aye Chan on 2/19/23.
//

import SwiftUI

struct FocusFrame: Shape {
    let lineWidth: CGFloat
    let lineHeight: CGFloat

    init(lineWidth: CGFloat = 4, lineHeight: CGFloat = 40) {
        self.lineWidth = lineWidth
        self.lineHeight = lineHeight
    }

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addPath(
                createCornersPath(
                    left: rect.minX + lineWidth / 2,
                    top: rect.minY + lineWidth / 2,
                    right: rect.width - lineWidth / 2,
                    bottom: rect.height - lineWidth / 2
                )
            )
        }
    }

    private func createCornersPath(
        left: CGFloat,
        top: CGFloat,
        right: CGFloat,
        bottom: CGFloat
    ) -> Path {
        var path = Path()

        // top left
        path.move(to: CGPoint(x: left, y: top + lineHeight))
        path.addLine(to: CGPoint(x: left, y: top))
        path.addLine(to: CGPoint(x: left + lineHeight, y: top))

        // top right
        path.move(to: CGPoint(x: right - lineHeight, y: top))
        path.addLine(to: CGPoint(x: right, y: top))
        path.addLine(to: CGPoint(x: right, y: top + lineHeight))

        // bottom right
        path.move(to: CGPoint(x: right, y: bottom - lineHeight))
        path.addLine(to: CGPoint(x: right, y: bottom))
        path.addLine(to: CGPoint(x: right - lineHeight, y: bottom))

        // bottom left
        path.move(to: CGPoint(x: left + lineHeight, y: bottom))
        path.addLine(to: CGPoint(x: left, y: bottom))
        path.addLine(to: CGPoint(x: left, y: bottom - lineHeight))

        return path.strokedPath(
            StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round
            )
        )
    }
}
