import SwiftUI
import WidgetKit

// MARK: - 5) Khatmah

struct KhatmahWidget: Widget {
    let kind = "AwwabKhatmah"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AwwabProvider()) { entry in
            KhatmahView(entry: entry)
        }
        .configurationDisplayName("الختمة")
        .description("ما تبقّى من وردك اليوم وموضع وقوفك في المصحف.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryRectangular,
        ])
    }
}

struct KhatmahView: View {
    let entry: AwwabEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content.awwabWidget(isAccessory: family.isAccessory)
    }

    @ViewBuilder
    private var content: some View {
        if let khatmah = entry.khatmah {
            switch family {
            case .accessoryCircular:
                Gauge(value: khatmah.todayFraction) {
                    Text("ورد")
                } currentValueLabel: {
                    if khatmah.isDone {
                        Image(systemName: "checkmark")
                    } else {
                        Text(arabicNumber(khatmah.remainingToday))
                    }
                }
                .gaugeStyle(.accessoryCircular)
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text("الختمة · ورد اليوم")
                        .font(.system(size: 13, weight: .bold))
                    Text(khatmah.isDone ? "أتممت وردك" : "متبقي \(arabicNumber(khatmah.remainingToday)) آية")
                        .font(.system(size: 14, weight: .semibold))
                    ProgressView(value: khatmah.todayFraction)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .systemMedium:
                KhatmahMedium(khatmah: khatmah)
            default:
                KhatmahSmall(khatmah: khatmah)
            }
        } else {
            KhatmahEmpty(family: family)
        }
    }
}

private struct KhatmahEmpty: View {
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "book.fill")
                    .font(.system(size: 20))
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("الختمة")
                    .font(.system(size: 13, weight: .bold))
                Text("افتح أواب وابدأ القراءة")
                    .font(.system(size: 12))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Brand.gold)
                Text("افتح أواب وابدأ القراءة")
                    .font(.system(size: 14, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct KhatmahRing: View {
    let khatmah: KhatmahState
    var numberSize: CGFloat = 30

    var body: some View {
        ZStack {
            Ring(fraction: khatmah.todayFraction, lineWidth: 9, tint: khatmah.isDone ? Brand.gold : Brand.mint)
            VStack(spacing: 0) {
                if khatmah.isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: numberSize, weight: .bold))
                        .foregroundStyle(Brand.gold)
                } else {
                    Text(arabicNumber(khatmah.remainingToday))
                        .font(.system(size: numberSize, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white)
                        .minimumScaleFactor(0.6)
                    Text("آية")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
        }
    }
}

private struct KhatmahSmall: View {
    let khatmah: KhatmahState

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "book.fill")
                Text("الختمة")
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.75))
            .frame(maxWidth: .infinity, alignment: .leading)

            KhatmahRing(khatmah: khatmah)
                .padding(.horizontal, 6)

            Text(khatmah.isDone ? "أتممت وردك اليوم" : "متبقي من وردك")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

private struct KhatmahMedium: View {
    let khatmah: KhatmahState

    private var position: String {
        guard let surah = khatmah.surah else { return "لم تبدأ بعد" }
        if let ayah = khatmah.ayah {
            return "سورة \(surah) · الآية \(arabicNumber(ayah))"
        }
        return "سورة \(surah)"
    }

    var body: some View {
        HStack(spacing: 16) {
            KhatmahRing(khatmah: khatmah, numberSize: 34)
                .frame(width: 104, height: 104)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    Image(systemName: "book.fill")
                    Text("الختمة")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Brand.gold)

                Text(khatmah.isDone
                    ? "أتممت وردك اليوم"
                    : "متبقي \(arabicNumber(khatmah.remainingToday)) آية من وردك")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("قرأت \(arabicNumber(khatmah.todayRead)) من \(arabicNumber(khatmah.dailyTarget)) آية")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))

                Spacer(minLength: 2)

                Text("وقفتَ عند \(position)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let book = khatmah.bookFraction, let page = khatmah.page {
                    Bar(fraction: book, tint: Brand.gold)
                    Text("صفحة \(arabicNumber(page)) من ٦٠٤")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

// MARK: - 6) Dhikr

struct DhikrWidget: Widget {
    let kind = "AwwabDhikr"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AwwabProvider()) { entry in
            DhikrView(entry: entry)
        }
        .configurationDisplayName("ذكر")
        .description("ذكر يتجدد كل ثلاث ساعات.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct DhikrView: View {
    let entry: AwwabEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content.awwabWidget(isAccessory: family.isAccessory)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("ذكر")
                    .font(.system(size: 12, weight: .bold))
                Text(entry.dhikr)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .systemMedium:
            dhikrCard(size: 20)
        default:
            dhikrCard(size: 14)
        }
    }

    private func dhikrCard(size: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                Text("ذكر")
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Brand.gold)

            Text(entry.dhikr)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(Color.white)
                .lineLimit(family == .systemMedium ? 4 : 6)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}
