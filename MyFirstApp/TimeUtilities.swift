import Foundation

class TimeUtilities {
    static func getCurrentTimeZoneSecondsFromGMT() -> Int {
        return TimeZone.current.secondsFromGMT()
    }

    static func getStringFromDate(date: Date, timeZone: TimeZone) -> String {
        return getDateFormatter(timeZone: timeZone).string(from: date)
    }

    static func getDateFromString(date: String, timeZone: TimeZone) -> Date {
        return getDateFormatter(timeZone: timeZone).date(from: date)!
    }

    private static func getDateFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        formatter.timeZone = timeZone

        return formatter
    }
}
