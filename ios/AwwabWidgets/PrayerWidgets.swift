import SwiftUI
import WidgetKit

// MARK: - 1) Next prayer

struct NextPrayerWidget: Widget {
    let kind = "AwwabNextPrayer"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AwwabProvider()) { entry in
            NextPrayerView(entry: entry)
        }
        .configurationDisplayName("الصلاة القادمة")
        .description("الوقت المتبقي للصلاة القادمة، على الشاشة الرئيسية وشاشة القفل.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryRectangular, .accessoryInline,
        ])
    }
}

struct NextPrayerView: View {
    let entry: AwwabEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content.awwabWidget(isAccessory: family.isAccessory)
    }

    @ViewBuilder
    private var content: some View {
        if let next = entry.next, entry.hasData {
            switch family {
            case .accessoryInline:
                Text("\(next.prayer.title) · ") + Text(next.date, style: .timer)
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 0) {
                        Image(systemName: next.prayer.symbol)
                            .font(.system(size: 11))
                        Text(next.prayer.title)
                            .font(.system(size: 12, weight: .bold))
                        Text(next.date, style: .timer)
                            .font(.system(size: 10, weight: .semibold))
                            .monospacedDigit()
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .frame(maxWidth: 46)
                    }
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 1) {
                    Text("الصلاة القادمة · \(next.prayer.title)")
                        .font(.system(size: 13, weight: .bold))
                    Text(next.date, style: .timer)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(entry.time(next.date))
                        .font(.system(size: 12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .systemMedium:
                NextPrayerMedium(entry: entry, next: next)
            default:
                NextPrayerSmall(entry: entry, next: next)
            }
        } else {
            WidgetEmptyState(family: family)
        }
    }
}

private struct NextPrayerSmall: View {
    let entry: AwwabEntry
    let next: PrayerEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Image(systemName: next.prayer.symbol)
                Text("الصلاة القادمة")
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.75))

            Text(next.prayer.title)
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(entry.time(next.date))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Brand.gold)

            Spacer(minLength: 0)

            Countdown(date: next.date, size: 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct NextPrayerMedium: View {
    let entry: AwwabEntry
    let next: PrayerEvent

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("الصلاة القادمة")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.75))
                Text(next.prayer.title)
                    .font(.system(size: 38, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 6) {
                    Text(entry.time(next.date))
                        .foregroundStyle(Brand.gold)
                    if !entry.city.isEmpty {
                        Text("· \(entry.city)")
                            .foregroundStyle(Color.white.opacity(0.65))
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            VStack(spacing: 6) {
                Image(systemName: next.prayer.symbol)
                    .font(.system(size: 26))
                    .foregroundStyle(Brand.gold)
                Text("المتبقي")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.65))
                Countdown(date: next.date, size: 30, alignment: .center)
            }
            .padding(12)
            .frame(maxWidth: 140, maxHeight: .infinity)
            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

// MARK: - 2) Previous and next prayer

struct PrevNextWidget: Widget {
    let kind = "AwwabPrevNext"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AwwabProvider()) { entry in
            PrevNextView(entry: entry)
        }
        .configurationDisplayName("السابقة والقادمة")
        .description("الصلاة التي مضت والصلاة القادمة مع الوقت المتبقي.")
        .supportedFamilies([.systemMedium, .accessoryRectangular])
    }
}

struct PrevNextView: View {
    let entry: AwwabEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content.awwabWidget(isAccessory: family.isAccessory)
    }

    @ViewBuilder
    private var content: some View {
        if let next = entry.next, entry.hasData {
            if family == .accessoryRectangular {
                VStack(alignment: .leading, spacing: 1) {
                    if let previous = entry.previous {
                        Text("مضت: \(previous.prayer.title) \(entry.time(previous.date))")
                            .font(.system(size: 12))
                    }
                    Text("القادمة: \(next.prayer.title)")
                        .font(.system(size: 13, weight: .bold))
                    Text(next.date, style: .timer)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                PrevNextMedium(entry: entry, next: next)
            }
        } else {
            WidgetEmptyState(family: family)
        }
    }
}

private struct PrevNextMedium: View {
    let entry: AwwabEntry
    let next: PrayerEvent

    var body: some View {
        HStack(spacing: 10) {
            // Previous
            VStack(alignment: .leading, spacing: 3) {
                Text("السابقة")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.65))
                if let previous = entry.previous {
                    Text(previous.prayer.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(entry.time(previous.date))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.65))
                    (Text("منذ ") + Text(previous.date, style: .relative))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    Text("—")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))

            // Next
            VStack(alignment: .leading, spacing: 2) {
                Text("القادمة")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Brand.gold)
                Text(next.prayer.title)
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(entry.time(next.date))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Brand.gold)
                Spacer(minLength: 0)
                Countdown(date: next.date, size: 22)
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - 3) Next prayer and a dhikr

struct PrayerDhikrWidget: Widget {
    let kind = "AwwabPrayerDhikr"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AwwabProvider()) { entry in
            PrayerDhikrView(entry: entry)
        }
        .configurationDisplayName("الصلاة القادمة وذكر")
        .description("الصلاة القادمة مع ذكر يتجدد على مدار اليوم.")
        .supportedFamilies([.systemMedium])
    }
}

struct PrayerDhikrView: View {
    let entry: AwwabEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content.awwabWidget(isAccessory: false)
    }

    @ViewBuilder
    private var content: some View {
        if let next = entry.next, entry.hasData {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("الصلاة القادمة")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.7))
                    Text(next.prayer.title)
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(entry.time(next.date))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Brand.gold)
                    Spacer(minLength: 0)
                    Countdown(date: next.date, size: 22)
                }
                .frame(maxWidth: 120, maxHeight: .infinity, alignment: .topLeading)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                        Text("ذكر")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Brand.gold)
                    Text(entry.dhikr)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .lineLimit(6)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
            }
        } else {
            WidgetEmptyState(family: family)
        }
    }
}

// MARK: - 4) Today's times

struct DayTimesWidget: Widget {
    let kind = "AwwabDayTimes"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AwwabProvider()) { entry in
            DayTimesView(entry: entry)
        }
        .configurationDisplayName("مواقيت اليوم")
        .description("مواقيت الصلوات الخمس والشروق، مع إبراز القادمة.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct DayTimesView: View {
    let entry: AwwabEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content.awwabWidget(isAccessory: false)
    }

    @ViewBuilder
    private var content: some View {
        if entry.hasData, !entry.day.isEmpty {
            VStack(spacing: family == .systemLarge ? 14 : 8) {
                header
                if family == .systemLarge {
                    DayList(entry: entry)
                } else {
                    DayRow(entry: entry)
                }
            }
        } else {
            WidgetEmptyState(family: family)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(entry.weekday()) · \(entry.hijri())")
                    .font(.system(size: family == .systemLarge ? 16 : 13, weight: .bold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if !entry.city.isEmpty {
                    Text(entry.city)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
            }
            Spacer(minLength: 8)
            if let next = entry.next {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                    Countdown(date: next.date, size: 13, color: Brand.mint, alignment: .trailing)
                        .frame(width: 64)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Brand.mint)
            }
        }
    }
}

private struct DayRow: View {
    let entry: AwwabEntry

    var body: some View {
        HStack(spacing: 4) {
            ForEach(entry.day, id: \.date) { event in
                let isNext = event == entry.next
                let isPast = event.date <= entry.date
                VStack(spacing: 4) {
                    Image(systemName: event.prayer.symbol)
                        .font(.system(size: 14))
                        .foregroundStyle(isNext ? Brand.gold : Color.white.opacity(isPast ? 0.45 : 0.85))
                    Text(event.prayer.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white.opacity(isPast && !isNext ? 0.55 : 1))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(entry.time(event.date))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isNext ? Brand.gold : Color.white.opacity(isPast ? 0.5 : 0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(isNext ? 0.22 : 0.07))
                )
            }
        }
        .frame(maxHeight: .infinity)
    }
}

private struct DayList: View {
    let entry: AwwabEntry

    var body: some View {
        VStack(spacing: 6) {
            ForEach(entry.day, id: \.date) { event in
                let isNext = event == entry.next
                let isPast = event.date <= entry.date
                HStack(spacing: 10) {
                    Image(systemName: event.prayer.symbol)
                        .font(.system(size: 18))
                        .frame(width: 26)
                        .foregroundStyle(isNext ? Brand.gold : Color.white.opacity(isPast ? 0.45 : 0.85))
                    Text(event.prayer.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.white.opacity(isPast && !isNext ? 0.55 : 1))
                    Spacer()
                    if isNext {
                        Countdown(date: event.date, size: 14, color: Brand.mint, alignment: .trailing)
                            .frame(width: 70)
                    }
                    Text(entry.time(event.date))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isNext ? Brand.gold : Color.white.opacity(isPast ? 0.5 : 0.9))
                }
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(isNext ? 0.2 : 0.07))
                )
            }
        }
        .frame(maxHeight: .infinity)
    }
}
