import SwiftUI
import WidgetKit

// MARK: - Brand

enum Brand {
    static let green = Color(red: 10 / 255, green: 124 / 255, blue: 102 / 255)
    static let deep = Color(red: 6 / 255, green: 78 / 255, blue: 64 / 255)
    static let night = Color(red: 7 / 255, green: 24 / 255, blue: 29 / 255)
    static let mint = Color(red: 45 / 255, green: 212 / 255, blue: 167 / 255)
    static let gold = Color(red: 245 / 255, green: 179 / 255, blue: 1 / 255)

    static var gradient: LinearGradient {
        LinearGradient(
            colors: [green, deep, night],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }
}

extension WidgetFamily {
    var isAccessory: Bool {
        switch self {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            return true
        default:
            return false
        }
    }
}

// MARK: - Container

/// Card background for the home screen; lock screen widgets stay transparent.
struct AwwabBackground: ViewModifier {
    let isAccessory: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(for: .widget) {
                if isAccessory {
                    Color.clear
                } else {
                    Brand.gradient
                }
            }
        } else {
            content
                .padding(isAccessory ? 0 : 14)
                .background(
                    isAccessory ? AnyView(Color.clear) : AnyView(Brand.gradient)
                )
        }
    }
}

/// Right-to-left layout and Arabic digits, whatever the phone language is.
struct AwwabEnvironment: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.locale, Locale(identifier: "ar-SA-u-nu-arab"))
    }
}

extension View {
    func awwabWidget(isAccessory: Bool) -> some View {
        modifier(AwwabEnvironment())
            .modifier(AwwabBackground(isAccessory: isAccessory))
    }
}

// MARK: - Shared pieces

/// Shown until the app has saved prayer times (or after they all passed).
struct WidgetEmptyState: View {
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("افتح أواب لتحديث المواقيت")
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 22))
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("أواب")
                    .font(.system(size: 13, weight: .bold))
                Text("افتح التطبيق لتحديث المواقيت")
                    .font(.system(size: 12))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Brand.gold)
                Text("افتح أواب لتحديث المواقيت")
                    .font(.system(size: 14, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Live countdown that keeps ticking without the widget being reloaded.
struct Countdown: View {
    let date: Date
    var size: CGFloat = 22
    var color: Color = Brand.mint
    var alignment: Alignment = .leading

    var body: some View {
        Text(date, style: .timer)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(color)
            .multilineTextAlignment(alignment == .center ? .center : .leading)
            .frame(maxWidth: .infinity, alignment: alignment)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}

/// Circular progress ring.
struct Ring: View {
    let fraction: Double
    var lineWidth: CGFloat = 9
    var tint: Color = Brand.mint

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(max(0.001, min(fraction, 1))))
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

/// Thin horizontal progress bar.
struct Bar: View {
    let fraction: Double
    var tint: Color = Brand.mint

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.18))
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * CGFloat(max(0, min(fraction, 1))))
            }
        }
        .frame(height: 6)
    }
}
