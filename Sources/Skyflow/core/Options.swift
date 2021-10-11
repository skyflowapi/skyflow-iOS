public struct Options {
    var logLevel: LogLevel
    public init(logLevel: LogLevel? = .DEBUG) {
        self.logLevel = logLevel!
    }
}
