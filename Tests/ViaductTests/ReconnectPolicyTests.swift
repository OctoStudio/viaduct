import Testing
@testable import Viaduct

@Suite("ReconnectPolicy")
struct ReconnectPolicyTests {

    @Test func initialDelayIsBase() {
        let policy = ReconnectPolicy(base: 1.0, cap: 60.0)
        #expect(policy.delay == 1.0)
    }

    @Test func exponentialBackoff() {
        var policy = ReconnectPolicy(base: 1.0, cap: 60.0)
        policy.increment()
        #expect(policy.delay == 2.0)
        policy.increment()
        #expect(policy.delay == 4.0)
        policy.increment()
        #expect(policy.delay == 8.0)
    }

    @Test func capEnforced() {
        var policy = ReconnectPolicy(base: 1.0, cap: 60.0)
        for _ in 0..<20 { policy.increment() }
        #expect(policy.delay <= 60.0)
    }

    @Test func resetRestoresBaseDelay() {
        var policy = ReconnectPolicy(base: 1.0, cap: 60.0)
        for _ in 0..<5 { policy.increment() }
        policy.reset()
        #expect(policy.delay == 1.0)
        #expect(policy.attempt == 0)
    }

    @Test func customBaseAndCap() {
        var policy = ReconnectPolicy(base: 2.0, cap: 10.0)
        #expect(policy.delay == 2.0)
        policy.increment()
        #expect(policy.delay == 4.0)
        policy.increment()
        #expect(policy.delay == 8.0)
        policy.increment()
        #expect(policy.delay == 10.0)
    }
}
