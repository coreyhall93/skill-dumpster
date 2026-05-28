import SkillDumpsterCore
import SwiftUI

enum DumpsterMotion {
    static let quick = Animation.spring(response: 0.20, dampingFraction: 0.86, blendDuration: 0.02)
    static let soft = Animation.spring(response: 0.28, dampingFraction: 0.88, blendDuration: 0.04)
    static let settle = Animation.spring(response: 0.38, dampingFraction: 0.92, blendDuration: 0.05)
    static let emphatic = Animation.spring(response: 0.32, dampingFraction: 0.72, blendDuration: 0.02)
}

enum DumpsterTheme {
    static let appBackground = Color(nsColor: .windowBackgroundColor)
    static let columnBackground = Color(nsColor: .underPageBackgroundColor).opacity(0.26)
    static let sidebarTint = Color.primary.opacity(0.035)
    static let detailTint = Color.primary.opacity(0.045)
    static let accentBlue = Color(red: 0.25, green: 0.43, blue: 0.68)
    static let accentBlueHighlight = Color(red: 0.12, green: 0.38, blue: 0.82)
    static let railIconDefault = Color(red: 0.45, green: 0.60, blue: 0.78)
    static let railIconHighlight = Color(red: 0.67, green: 0.80, blue: 0.98)
    static let selection = accentBlueHighlight
    static let hoverFill = Color.primary.opacity(0.070)
    static let pressedFill = Color.primary.opacity(0.120)
    static let selectedRowFill = Color.primary.opacity(0.060)
    static let selectedRowStroke = Color.primary.opacity(0.145)
    static let divider = Color(nsColor: .separatorColor).opacity(0.58)
    static let controlStroke = Color.primary.opacity(0.150)
    static let quietStroke = Color.primary.opacity(0.100)
    static let warmSurface = Color(nsColor: .controlBackgroundColor).opacity(0.54)
    static let commandSurface = Color(nsColor: .windowBackgroundColor).opacity(0.985)
    static let controlSurface = Color.primary.opacity(0.050)
    static let tileSurface = Color(nsColor: .textBackgroundColor).opacity(0.98)
    static let tileHoverSurface = Color.primary.opacity(0.035)
    static let selectedTileSurface = accentBlueHighlight.opacity(0.070)
    static let panelSurface = Color(nsColor: .textBackgroundColor).opacity(0.985)
    static let insetSurface = Color(nsColor: .controlBackgroundColor).opacity(0.62)
    static let railSurface = Color(red: 0.165, green: 0.175, blue: 0.185)
    static let railForeground = Color.white.opacity(0.84)
    static let railMuted = Color.white.opacity(0.56)
    static let railHover = accentBlue.opacity(0.16)
    static let railSelected = accentBlueHighlight.opacity(0.22)
    static let success = Color(red: 0.16, green: 0.51, blue: 0.46)
    static let amber = Color(red: 0.70, green: 0.45, blue: 0.16)
    static let rust = accentBlue
    static let moss = accentBlue
    static let steel = Color(red: 0.37, green: 0.43, blue: 0.53)
    static let paper = Color(nsColor: .textBackgroundColor).opacity(0.985)

    static let primaryText = Color.primary.opacity(0.90)
    static let secondaryText = Color.secondary.opacity(0.86)
    static let tertiaryText = Color.secondary.opacity(0.68)

    static func appWash(for scheme: ColorScheme) -> LinearGradient {
        let top = scheme == .dark
            ? Color(red: 0.075, green: 0.078, blue: 0.082)
            : Color(red: 0.965, green: 0.962, blue: 0.952)
        let bottom = scheme == .dark
            ? Color(red: 0.055, green: 0.058, blue: 0.062)
            : Color(red: 0.925, green: 0.922, blue: 0.908)

        return LinearGradient(
            colors: [top, bottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func patternInk(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.035) : Color.black.opacity(0.026)
    }

    static func panelFill(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.045) : Color.white.opacity(0.44)
    }

    static func sectionAccent(for _: RummageSection) -> Color {
        accentBlueHighlight
    }

    static func sourceAccent(for _: SkillKind) -> Color {
        accentBlue
    }

    static func sourceWash(for kind: SkillKind) -> Color {
        sourceAccent(for: kind).opacity(0.16)
    }

    static func badgeBackground(for kind: SkillKind) -> Color {
        sourceAccent(for: kind)
    }
}

struct DumpsterBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        DumpsterTheme.appWash(for: colorScheme)
        .ignoresSafeArea()
    }
}

enum DumpsterFont {
    private static let family = "Geist"

    static func body(_ weight: Font.Weight = .regular) -> Font {
        font(.body, size: 15, weight: weight)
    }

    static func callout(_ weight: Font.Weight = .regular) -> Font {
        font(.callout, size: 15, weight: weight)
    }

    static func caption(_ weight: Font.Weight = .regular) -> Font {
        font(.caption, size: 12, weight: weight)
    }

    static func footnote(_ weight: Font.Weight = .regular) -> Font {
        font(.footnote, size: 13, weight: weight)
    }

    static func headline(_ weight: Font.Weight = .regular) -> Font {
        font(.headline, size: 17, weight: weight)
    }

    static func subheadline(_ weight: Font.Weight = .regular) -> Font {
        font(.subheadline, size: 14, weight: weight)
    }

    static func title2(_ weight: Font.Weight = .regular) -> Font {
        font(.title2, size: 22, weight: weight)
    }

    static func title3(_ weight: Font.Weight = .regular) -> Font {
        font(.title3, size: 20, weight: weight)
    }

    static func fixed(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom(family, size: size).weight(weight)
    }

    private static func font(_ style: Font.TextStyle, size: CGFloat, weight: Font.Weight) -> Font {
        .custom(family, size: size, relativeTo: style).weight(weight)
    }
}

struct SoftPanel: ViewModifier {
    let cornerRadius: CGFloat
    let isProminent: Bool

    func body(content: Content) -> some View {
        content
            .background(isProminent ? DumpsterTheme.panelSurface : DumpsterTheme.insetSurface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isProminent ? DumpsterTheme.controlStroke : DumpsterTheme.quietStroke, lineWidth: 1)
            )
    }
}

private struct PressableSurface: ViewModifier {
    let isHovering: Bool
    let isPressed: Bool
    let cornerRadius: CGFloat
    let selected: Bool

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(stroke, lineWidth: selected ? 1 : 0)
            )
            .scaleEffect(isPressed ? 0.985 : isHovering ? 1.006 : 1)
            .animation(DumpsterMotion.quick, value: isHovering)
            .animation(DumpsterMotion.quick, value: isPressed)
            .animation(DumpsterMotion.soft, value: selected)
    }

    private var fill: Color {
        if selected {
            return DumpsterTheme.selectedRowFill
        }
        if isPressed {
            return DumpsterTheme.pressedFill
        }
        if isHovering {
            return DumpsterTheme.hoverFill
        }
        return .clear
    }

    private var stroke: Color {
        selected ? DumpsterTheme.selectedRowStroke : .clear
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 12, prominent: Bool = true) -> some View {
        modifier(SoftPanel(cornerRadius: cornerRadius, isProminent: prominent))
    }

    func tactileSurface(
        isHovering: Bool,
        isPressed: Bool = false,
        cornerRadius: CGFloat = 10,
        selected: Bool = false
    ) -> some View {
        modifier(
            PressableSurface(
                isHovering: isHovering,
                isPressed: isPressed,
                cornerRadius: cornerRadius,
                selected: selected
            )
        )
    }
}
