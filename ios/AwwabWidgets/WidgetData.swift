import SwiftUI
import WidgetKit

// MARK: - Shared storage

/// The widgets read what the Flutter app wrote into the shared App Group.
enum AppGroup {
    static let id = "group.com.alray.azkarna"
    static let payloadKey = "awwab_widget_payload"
}

// MARK: - Model

enum Salat: String {
    case fajr, sunrise, dhuhr, asr, maghrib, isha

    var title: String {
        switch self {
        case .fajr: return "الفجر"
        case .sunrise: return "الشروق"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        }
    }

    var symbol: String {
        switch self {
        case .fajr: return "moon.haze.fill"
        case .sunrise: return "sunrise.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.haze.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.stars.fill"
        }
    }
}

struct PrayerEvent: Equatable {
    let prayer: Salat
    let date: Date
}

struct KhatmahState: Equatable {
    let dailyTarget: Int
    let todayRead: Int
    let surah: String?
    let ayah: Int?
    let page: Int?

    var remainingToday: Int { max(dailyTarget - todayRead, 0) }
    var isDone: Bool { dailyTarget > 0 && todayRead >= dailyTarget }
    var todayFraction: Double {
        dailyTarget <= 0 ? 0 : min(Double(todayRead) / Double(dailyTarget), 1)
    }
    /// How far through the Mushaf (604 pages) the bookmark is.
    var bookFraction: Double? {
        guard let page = page else { return nil }
        return min(Double(page) / 604.0, 1)
    }
}

/// JSON written by `lib/features/widgets` in the Flutter app.
struct WidgetPayload: Decodable {
    struct Event: Decodable {
        let p: String
        let t: Double
    }

    struct Khatmah: Decodable {
        let target: Int
        let read: Int
        let readDay: String
        let surah: String?
        let ayah: Int?
        let page: Int?
    }

    let utcOffset: Int
    let city: String
    let events: [Event]
    let khatmah: Khatmah?
}

struct WidgetSnapshot {
    let events: [PrayerEvent]
    let timeZone: TimeZone
    let city: String
    let khatmah: WidgetPayload.Khatmah?

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    func previous(at date: Date) -> PrayerEvent? {
        events.last(where: { $0.date <= date })
    }

    func next(at date: Date) -> PrayerEvent? {
        events.first(where: { $0.date > date })
    }

    /// The prayers of the calendar day (at the saved location) containing [date].
    func day(of date: Date) -> [PrayerEvent] {
        events.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func khatmahState(at date: Date) -> KhatmahState? {
        guard let k = khatmah else { return nil }
        let read = k.readDay == WidgetSnapshot.dayKey(date) ? k.read : 0
        return KhatmahState(
            dailyTarget: k.target,
            todayRead: read,
            surah: k.surah,
            ayah: k.ayah,
            page: k.page
        )
    }

    /// `yyyy-MM-dd` in the device calendar, same format the app uses.
    static func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func load() -> WidgetSnapshot? {
        guard
            let defaults = UserDefaults(suiteName: AppGroup.id),
            let json = defaults.string(forKey: AppGroup.payloadKey),
            let data = json.data(using: .utf8),
            let payload = try? JSONDecoder().decode(WidgetPayload.self, from: data)
        else { return nil }

        let events = payload.events
            .compactMap { event -> PrayerEvent? in
                guard let prayer = Salat(rawValue: event.p) else { return nil }
                return PrayerEvent(
                    prayer: prayer,
                    date: Date(timeIntervalSince1970: event.t)
                )
            }
            .sorted { $0.date < $1.date }

        return WidgetSnapshot(
            events: events,
            timeZone: TimeZone(secondsFromGMT: payload.utcOffset) ?? .current,
            city: payload.city,
            khatmah: payload.khatmah
        )
    }
}

// MARK: - Timeline entry

struct AwwabEntry: TimelineEntry {
    let date: Date
    /// False until the app wrote times, or once the saved times ran out.
    let hasData: Bool
    let previous: PrayerEvent?
    let next: PrayerEvent?
    let day: [PrayerEvent]
    let city: String
    let timeZone: TimeZone
    let khatmah: KhatmahState?
    let dhikr: String

    /// Clock time with Arabic digits, at the saved location.
    func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.timeZone = timeZone
        formatter.dateFormat = "h:mm a"
        return arabicDigits(formatter.string(from: date))
    }

    func weekday() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    /// Umm Al-Qura Hijri date, e.g. `٢٠ ربيع الآخر ١٤٤٨ هـ`.
    func hijri() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.locale = Locale(identifier: "ar")
        formatter.timeZone = timeZone
        formatter.dateFormat = "d MMMM y"
        return arabicDigits(formatter.string(from: date)) + " هـ"
    }

    static func empty(at date: Date) -> AwwabEntry {
        AwwabEntry(
            date: date,
            hasData: false,
            previous: nil,
            next: nil,
            day: [],
            city: "",
            timeZone: .current,
            khatmah: nil,
            dhikr: DhikrLibrary.item(at: date)
        )
    }

    /// Realistic fake data for the widget gallery and placeholders.
    static func sample(at date: Date = Date()) -> AwwabEntry {
        func event(_ prayer: Salat, _ minutes: Double) -> PrayerEvent {
            PrayerEvent(prayer: prayer, date: date.addingTimeInterval(minutes * 60))
        }
        let day = [
            event(.fajr, -540),
            event(.sunrise, -470),
            event(.dhuhr, -95),
            event(.asr, 87),
            event(.maghrib, 250),
            event(.isha, 330),
        ]
        return AwwabEntry(
            date: date,
            hasData: true,
            previous: day[2],
            next: day[3],
            day: day,
            city: "حائل",
            timeZone: .current,
            khatmah: KhatmahState(
                dailyTarget: 20,
                todayRead: 12,
                surah: "الكهف",
                ayah: 45,
                page: 300
            ),
            dhikr: DhikrLibrary.items[0]
        )
    }
}

// MARK: - Timeline provider

struct AwwabProvider: TimelineProvider {
    /// Entries cover this long; WidgetKit then asks for a new timeline.
    private static let horizon: TimeInterval = 36 * 3600
    private static let tick: TimeInterval = 3 * 3600

    func placeholder(in context: Context) -> AwwabEntry {
        AwwabEntry.sample()
    }

    func getSnapshot(in context: Context, completion: @escaping (AwwabEntry) -> Void) {
        if context.isPreview {
            completion(AwwabEntry.sample())
        } else {
            completion(AwwabProvider.entries(from: Date()).first ?? .empty(at: Date()))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AwwabEntry>) -> Void) {
        let now = Date()
        let entries = AwwabProvider.entries(from: now)
        let last = entries.last?.date ?? now
        // Ask again once the last entry started (and never sooner than 30 min
        // when there is nothing to show).
        let refresh = entries.count > 1 ? last : now.addingTimeInterval(30 * 60)
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }

    static func entries(from now: Date) -> [AwwabEntry] {
        guard let snapshot = WidgetSnapshot.load() else {
            return [AwwabEntry.empty(at: now)]
        }

        let end = now.addingTimeInterval(horizon)
        var stamps: Set<TimeInterval> = [now.timeIntervalSince1970.rounded()]

        // A new entry at every prayer, so previous/next flip on time.
        for event in snapshot.events where event.date > now && event.date <= end {
            stamps.insert(event.date.timeIntervalSince1970.rounded())
        }
        // Rotating dhikr and a fresh day (date, Khatmah quota) at midnight.
        var tick = now.addingTimeInterval(AwwabProvider.tick)
        while tick <= end {
            stamps.insert(tick.timeIntervalSince1970.rounded())
            tick = tick.addingTimeInterval(AwwabProvider.tick)
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = snapshot.timeZone
        if let midnight = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 5),
            matchingPolicy: .nextTime
        ), midnight <= end {
            stamps.insert(midnight.timeIntervalSince1970.rounded())
        }

        return stamps.sorted().map { stamp in
            let date = Date(timeIntervalSince1970: stamp)
            let next = snapshot.next(at: date)
            return AwwabEntry(
                date: date,
                hasData: next != nil,
                previous: snapshot.previous(at: date),
                next: next,
                day: snapshot.day(of: date),
                city: snapshot.city,
                timeZone: snapshot.timeZone,
                khatmah: snapshot.khatmahState(at: date),
                dhikr: DhikrLibrary.item(at: date)
            )
        }
    }
}

// MARK: - Dhikr

enum DhikrLibrary {
    static let items: [String] = [
        "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ",
        "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ",
        "أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ",
        "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ",
        "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
        "حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ",
        "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ",
        "رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ",
        "سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ",
        "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ",
        "اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي",
        "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
        "لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ",
        "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
    ]

    /// Changes every three hours; stable for a given moment.
    static func item(at date: Date) -> String {
        let slot = Int(date.timeIntervalSince1970 / (3 * 3600))
        return items[((slot % items.count) + items.count) % items.count]
    }
}

// MARK: - Helpers

/// Replaces Western digits with Arabic-Indic digits.
func arabicDigits(_ text: String) -> String {
    let arabic: [Character] = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
    return String(text.map { character -> Character in
        if let digit = character.wholeNumberValue,
            character.isASCII,
            digit >= 0 && digit <= 9
        {
            return arabic[digit]
        }
        return character
    })
}

func arabicNumber(_ value: Int) -> String {
    arabicDigits(String(value))
}
