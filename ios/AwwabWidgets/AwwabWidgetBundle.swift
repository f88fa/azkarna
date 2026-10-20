import SwiftUI
import WidgetKit

@main
struct AwwabWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextPrayerWidget()
        PrevNextWidget()
        PrayerDhikrWidget()
        DayTimesWidget()
        KhatmahWidget()
        DhikrWidget()
    }
}
