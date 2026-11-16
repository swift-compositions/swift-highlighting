#if Swift
    extension Highlighting.Swift.Reference {
        struct Position: Sendable, Hashable {
            let line: Int
            let column: Int
        }
    }
#endif
