#if Swift
    extension Highlighting.Swift.Reference {
        enum Kind: Sendable, Equatable {
            case local
            case project
            case system(emitted: Bool)
        }
    }
#endif
