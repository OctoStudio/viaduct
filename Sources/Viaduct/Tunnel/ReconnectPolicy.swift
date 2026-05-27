import Foundation

struct ReconnectPolicy {
    private(set) var attempt: Int = 0
    let base: TimeInterval
    let cap: TimeInterval

    init(base: TimeInterval = 1.0, cap: TimeInterval = 60.0) {
        self.base = base
        self.cap = cap
    }

    var delay: TimeInterval {
        let exponential = base * pow(2.0, Double(attempt))
        return min(exponential, cap)
    }

    mutating func increment() {
        attempt += 1
    }

    mutating func reset() {
        attempt = 0
    }
}
