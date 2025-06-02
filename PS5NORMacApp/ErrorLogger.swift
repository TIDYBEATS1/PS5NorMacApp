import FirebaseCrashlytics

struct ErrorLogger {
    static func log(_ error: Error, additionalInfo: [String: Any]? = nil) {
        let crashlytics = Crashlytics.crashlytics()
        
        // Attach any extra info as custom keys
        if let info = additionalInfo {
            for (key, value) in info {
                if let stringValue = value as? String {
                    crashlytics.setCustomValue(stringValue, forKey: key)
                } else {
                    crashlytics.setCustomValue("\(value)", forKey: key)
                }
            }
        }
        
        // Record the error with Crashlytics
        crashlytics.record(error: error)
    }
}
