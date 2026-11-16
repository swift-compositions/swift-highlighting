extension Highlighting {
    /// What a token is to the reader.
    public enum Role: Sendable, Hashable, CaseIterable {
        case plain
        case keyword
        case string
        case number
        case comment
        case declarationType
        case declarationOther
        case projectType
        case projectMember
        case projectLabel
        case systemType
        case systemMember
    }
}
