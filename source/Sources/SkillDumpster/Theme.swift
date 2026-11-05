import SkillDumpsterCore
import SwiftUI

extension SkillKind {
    var symbolName: String {
        switch self {
        case .agents: "person.2"
        case .claude: "sparkle"
        case .claudePlugin: "puzzlepiece.extension"
        case .codex: "chevron.left.forwardslash.chevron.right"
        case .codexPlugin: "shippingbox"
        case .codexSystem: "lock"
        case .grok: "bolt"
        case .custom: "folder"
        }
    }

    var tint: Color {
        switch self {
        case .agents: .teal
        case .claude, .claudePlugin: .orange
        case .codex, .codexPlugin: .blue
        case .codexSystem: .gray
        case .grok: .purple
        case .custom: .green
        }
    }
}

/// A small rounded tile with the source's symbol, used in rows and the detail header.
struct KindIcon: View {
    let kind: SkillKind
    var size: CGFloat = 28

    var body: some View {
        Image(systemName: kind.symbolName)
            .font(.system(size: size * 0.46, weight: .semibold))
            .foregroundStyle(kind.tint)
            .frame(width: size, height: size)
            .background(kind.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct Pill: View {
    let text: String
    var systemImage: String?
    var tint: Color = .secondary

    var body: some View {
        Group {
            if let systemImage {
                Label(text, systemImage: systemImage)
            } else {
                Text(text)
            }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(tint.opacity(0.12), in: Capsule())
        .fixedSize()
    }
}

enum Format {
    static func relative(_ date: Date) -> String {
        date.formatted(.relative(presentation: .named, unitsStyle: .abbreviated))
    }
}
