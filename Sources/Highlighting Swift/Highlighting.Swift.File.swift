#if Swift
    extension Highlighting.Swift {
        /// One Swift source file of a project: its name, relative to the project, and its text.
        public struct File: Sendable, Hashable {
            public var name: String
            public var text: String

            public init(name: String, text: String) {
                self.name = name
                self.text = text
            }
        }
    }
#endif
