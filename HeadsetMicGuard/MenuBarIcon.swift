//
//  MenuBarIcon.swift
//  HeadsetMicGuard
//
//  Created by Kiryl Shcherba on 21/05/2026.
//

import AppKit

enum MenuBarIconState {
    case guarding
    case paused
    case switching
    case unavailable
    case attention
}

enum MenuBarIcon {
    static func image(for state: MenuBarIconState) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)

        image.lockFocus()
        NSGraphicsContext.current?.shouldAntialias = true
        drawShieldMic(in: NSRect(origin: .zero, size: size), state: state)
        image.unlockFocus()

        image.isTemplate = false
        return image
    }

    private static func drawShieldMic(in rect: NSRect, state: MenuBarIconState) {
        let baseColor = NSColor.labelColor
        let secondaryColor = NSColor.secondaryLabelColor
        let badgeColor = color(for: state)

        let shield = NSBezierPath()
        shield.move(to: NSPoint(x: rect.midX, y: 16.35))
        shield.curve(to: NSPoint(x: 15.2, y: 13.85),
                     controlPoint1: NSPoint(x: 10.7, y: 15.9),
                     controlPoint2: NSPoint(x: 13.15, y: 15.1))
        shield.curve(to: NSPoint(x: 9.0, y: 1.65),
                     controlPoint1: NSPoint(x: 15.05, y: 8.45),
                     controlPoint2: NSPoint(x: 12.9, y: 4.0))
        shield.curve(to: NSPoint(x: 2.8, y: 13.85),
                     controlPoint1: NSPoint(x: 5.1, y: 4.0),
                     controlPoint2: NSPoint(x: 2.95, y: 8.45))
        shield.curve(to: NSPoint(x: rect.midX, y: 16.35),
                     controlPoint1: NSPoint(x: 4.85, y: 15.1),
                     controlPoint2: NSPoint(x: 7.3, y: 15.9))
        shield.close()

        baseColor.withAlphaComponent(0.18).setFill()
        shield.fill()

        baseColor.setStroke()
        shield.lineWidth = 1.35
        shield.lineJoinStyle = .round
        shield.stroke()

        let mic = NSBezierPath(roundedRect: NSRect(x: 6.45, y: 7.0, width: 5.1, height: 6.85),
                               xRadius: 2.55,
                               yRadius: 2.55)
        baseColor.setStroke()
        mic.lineWidth = 1.25
        mic.stroke()

        let stand = NSBezierPath()
        stand.move(to: NSPoint(x: 9.0, y: 4.8))
        stand.line(to: NSPoint(x: 9.0, y: 6.85))
        stand.move(to: NSPoint(x: 6.85, y: 4.75))
        stand.line(to: NSPoint(x: 11.15, y: 4.75))
        secondaryColor.setStroke()
        stand.lineWidth = 1.15
        stand.lineCapStyle = .round
        stand.stroke()

        drawBadge(state: state, color: badgeColor)
    }

    private static func drawBadge(state: MenuBarIconState, color: NSColor) {
        let badgeRect = NSRect(x: 11.2, y: 1.55, width: 5.7, height: 5.7)
        let badge = NSBezierPath(ovalIn: badgeRect)

        color.setFill()
        badge.fill()

        NSColor.white.withAlphaComponent(0.95).setStroke()

        switch state {
        case .guarding:
            let dot = NSBezierPath(ovalIn: NSRect(x: 13.2, y: 3.55, width: 1.7, height: 1.7))
            NSColor.white.withAlphaComponent(0.95).setFill()
            dot.fill()

        case .paused:
            NSColor.white.withAlphaComponent(0.95).setFill()
            NSBezierPath(roundedRect: NSRect(x: 12.95, y: 3.05, width: 0.75, height: 2.8),
                         xRadius: 0.35,
                         yRadius: 0.35).fill()
            NSBezierPath(roundedRect: NSRect(x: 14.35, y: 3.05, width: 0.75, height: 2.8),
                         xRadius: 0.35,
                         yRadius: 0.35).fill()

        case .switching:
            let arrow = NSBezierPath()
            arrow.move(to: NSPoint(x: 12.75, y: 5.15))
            arrow.line(to: NSPoint(x: 14.25, y: 5.75))
            arrow.line(to: NSPoint(x: 15.3, y: 4.55))
            arrow.move(to: NSPoint(x: 15.25, y: 3.45))
            arrow.line(to: NSPoint(x: 13.75, y: 2.85))
            arrow.line(to: NSPoint(x: 12.7, y: 4.05))
            arrow.lineWidth = 0.8
            arrow.lineCapStyle = .round
            arrow.lineJoinStyle = .round
            arrow.stroke()

        case .unavailable, .attention:
            let mark = NSBezierPath()
            mark.move(to: NSPoint(x: 14.05, y: 5.75))
            mark.line(to: NSPoint(x: 14.05, y: 3.65))
            mark.lineWidth = 0.85
            mark.lineCapStyle = .round
            mark.stroke()

            NSColor.white.withAlphaComponent(0.95).setFill()
            NSBezierPath(ovalIn: NSRect(x: 13.67, y: 2.55, width: 0.8, height: 0.8)).fill()
        }
    }

    private static func color(for state: MenuBarIconState) -> NSColor {
        switch state {
        case .guarding:
            return NSColor.systemGreen
        case .paused:
            return NSColor.systemGray
        case .switching:
            return NSColor.systemBlue
        case .unavailable:
            return NSColor.systemOrange
        case .attention:
            return NSColor.systemRed
        }
    }
}
