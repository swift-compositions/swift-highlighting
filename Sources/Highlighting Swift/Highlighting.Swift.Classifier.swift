#if Swift
    import SwiftSyntax

    extension Highlighting.Swift {
        struct Classifier {
            let converter: SourceLocationConverter
            let types: Set<String>
            let references: [Reference.Position: Reference]
        }
    }

    extension Highlighting.Swift.Classifier {
        func role(of token: TokenSyntax) -> Highlighting.Role { Self.role(self, of: token) }

        static func role(_ classifier: Self, of token: TokenSyntax) -> Highlighting.Role {
            switch token.tokenKind {
            case .keyword: .keyword
            case .stringQuote, .stringSegment, .multilineStringQuote, .rawStringPoundDelimiter, .singleQuote: .string
            case .integerLiteral, .floatLiteral: .number
            case .atSign: token.nextToken(viewMode: .sourceAccurate).map { Self.role(classifier, of: $0) } ?? .plain
            case .identifier, .dollarIdentifier: Self.identifier(classifier, token)
            default: .plain
            }
        }

        static func identifier(_ classifier: Self, _ token: TokenSyntax) -> Highlighting.Role {
            guard let parent = token.parent else { return .plain }
            if parent.is(ImportPathComponentSyntax.self) { return .plain }
            if Highlighting.Swift.declaresType(parent) { return .declarationType }
            if parent.is(FunctionDeclSyntax.self) { return .declarationOther }
            if parent.is(IdentifierPatternSyntax.self) { return Self.member(parent) ? .declarationOther : .plain }
            if let label = parent.as(LabeledExprSyntax.self), label.label == token { return Self.labelled(classifier, label) }
            if parent.is(IdentifierTypeSyntax.self) || parent.is(MemberTypeSyntax.self) {
                if parent.parent?.is(AttributeSyntax.self) == true {
                    return classifier.types.contains(token.text) ? .projectType : .systemMember
                }
                return classifier.types.contains(token.text) ? .projectType : .systemType
            }
            if parent.is(DeclReferenceExprSyntax.self) { return Self.reference(classifier, token) }
            return .plain
        }

        static func member(_ pattern: Syntax) -> Bool {
            var node = pattern.parent
            while let current = node {
                if current.is(VariableDeclSyntax.self) {
                    return current.parent?.is(MemberBlockItemSyntax.self) == true || current.parent?.parent?.parent?.is(SourceFileSyntax.self) == true
                }
                node = current.parent
            }
            return false
        }

        static func labelled(_ classifier: Self, _ label: LabeledExprSyntax) -> Highlighting.Role {
            guard let call = label.parent?.parent?.as(FunctionCallExprSyntax.self), let callee = call.calledExpression.lastToken(viewMode: .sourceAccurate) else {
                return .plain
            }
            switch Self.role(classifier, of: callee) {
            case .projectType, .projectMember: return .projectLabel
            case .systemType, .systemMember: return .systemMember
            default: return .plain
            }
        }

        static func reference(_ classifier: Self, _ token: TokenSyntax) -> Highlighting.Role {
            let location = token.startLocation(converter: classifier.converter)
            guard let reference = classifier.references[Highlighting.Swift.Reference.Position(line: location.line, column: location.column)] else {
                if classifier.types.contains(token.text) { return .projectType }
                return token.text.first?.isUppercase == true ? .systemType : .plain
            }
            let type = token.text.first?.isUppercase == true
            switch reference.kind {
            case .local: return .plain
            case .project: return type ? .projectType : .projectMember
            case .system(let emitted): return type ? .systemType : emitted ? .plain : .systemMember
            }
        }
    }
#endif
