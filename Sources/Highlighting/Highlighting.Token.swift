extension Highlighting {
    /// A run of source text and the role it plays.
    public struct Token: Sendable, Hashable {
        public var text: String
        public var role: Role

        public init(text: String, role: Role) {
            self.text = text
            self.role = role
        }
    }
}
