//
//  Theme.swift
//  BatteryManager
//
//  Created by Dhanilka Dasanayake on 3/8/26.
//

import AppKit
import SwiftUI

enum AppThemeMode: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

struct Theme {
    // MARK: - Colors
    struct Colors {
        static let background = adaptive(light: NSColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1.0), dark: .black)
        static let cardBackground = adaptive(light: NSColor.white, dark: NSColor(white: 0.06, alpha: 1.0))
        static let primary = adaptive(light: NSColor(red: 0.10, green: 0.12, blue: 0.15, alpha: 1.0), dark: .white)
        static let secondary = adaptive(light: NSColor(red: 0.39, green: 0.43, blue: 0.49, alpha: 1.0), dark: NSColor(white: 0.65, alpha: 1.0))
        static let tertiary = adaptive(light: NSColor(red: 0.55, green: 0.58, blue: 0.62, alpha: 1.0), dark: NSColor(white: 0.45, alpha: 1.0))
        static let accent = adaptive(light: .systemBlue, dark: .white)
        static let border = adaptive(light: NSColor(red: 0.84, green: 0.86, blue: 0.90, alpha: 1.0), dark: NSColor(white: 0.20, alpha: 1.0))
        static let success = Color.green
        static let warning = Color.orange
        static let danger = Color.red

        private static func adaptive(light: NSColor, dark: NSColor) -> Color {
            let dynamic = NSColor(name: nil) { appearance in
                let match = appearance.bestMatch(from: [.aqua, .darkAqua])
                return match == .darkAqua ? dark : light
            }
            return Color(nsColor: dynamic)
        }
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        
        // Monospaced for numbers
        static let monoLarge = Font.system(size: 48, weight: .bold, design: .rounded).monospacedDigit()
        static let monoMedium = Font.system(size: 32, weight: .semibold, design: .rounded).monospacedDigit()
        static let monoSmall = Font.system(size: 20, weight: .medium, design: .rounded).monospacedDigit()
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 20
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = Shadow(
            color: Color.black.opacity(0.3),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let medium = Shadow(
            color: Color.black.opacity(0.4),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let large = Shadow(
            color: Color.black.opacity(0.5),
            radius: 16,
            x: 0,
            y: 8
        )
    }
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    // MARK: - Animation
    struct Animation {
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
    
    // MARK: - Icon Sizes
    struct IconSize {
        static let small: CGFloat = 16
        static let medium: CGFloat = 24
        static let large: CGFloat = 32
        static let xlarge: CGFloat = 48
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
    }
}

struct GlassmorphicStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Theme.Colors.cardBackground.opacity(0.8)
            )
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Theme.Colors.border.opacity(0.5), lineWidth: 1)
            )
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func glassmorphic() -> some View {
        modifier(GlassmorphicStyle())
    }
}
