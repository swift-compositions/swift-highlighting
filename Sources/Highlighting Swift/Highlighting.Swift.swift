#if Swift
    import SwiftParser
    import SwiftSyntax

    extension Highlighting {
        /// Swift source cut into tokens by role, in the context of the project it belongs to.
        public enum Swift {}
    }

    extension Highlighting.Swift {
        /// The lines of `shown`, each a run of tokens whose texts join back into the line.
        ///
        /// `project` is every file the compiler needs to resolve the names in `shown`, `shown` among them.
        public static func lines(of shown: File, in project: [File]) -> [[Highlighting.Token]] {
            let tree = Parser.parse(source: shown.text)
            let classifier = Classifier(
                converter: SourceLocationConverter(fileName: shown.name, tree: tree),
                types: Set(project.flatMap { Self.types(declaredIn: Parser.parse(source: $0.text)) }),
                references: Reference.resolve(shown, in: project)
            )
            var tokens: [Highlighting.Token] = []
            for token in tree.tokens(viewMode: .sourceAccurate) {
                tokens += trivia(token.leadingTrivia)
                tokens.append(Highlighting.Token(text: token.text, role: classifier.role(of: token)))
                tokens += trivia(token.trailingTrivia)
            }
            return split(tokens)
        }

        static func trivia(_ trivia: Trivia) -> [Highlighting.Token] {
            trivia.pieces.map { piece in
                var text = ""
                piece.write(to: &text)
                switch piece {
                case .lineComment, .blockComment, .docLineComment, .docBlockComment: return Highlighting.Token(text: text, role: .comment)
                default: return Highlighting.Token(text: text, role: .plain)
                }
            }
        }

        static func split(_ tokens: [Highlighting.Token]) -> [[Highlighting.Token]] {
            var lines: [[Highlighting.Token]] = [[]]
            for token in tokens {
                for (index, part) in token.text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                    if index > 0 { lines.append([]) }
                    if !part.isEmpty, let last = lines.indices.last {
                        lines[last].append(Highlighting.Token(text: String(part), role: token.role))
                    }
                }
            }
            return lines
        }

        static func types(declaredIn tree: SourceFileSyntax) -> [String] {
            tree.tokens(viewMode: .sourceAccurate).compactMap { token in
                guard let parent = token.parent, declaresType(parent), Self.identifies(token.tokenKind) else { return nil }
                return token.text
            }
        }

        static func identifies(_ kind: TokenKind) -> Bool {
            if case .identifier = kind { true } else { false }
        }

        static func declaresType(_ node: Syntax) -> Bool {
            node.is(StructDeclSyntax.self) || node.is(ClassDeclSyntax.self) || node.is(EnumDeclSyntax.self) || node.is(ActorDeclSyntax.self)
                || node.is(ProtocolDeclSyntax.self) || node.is(TypeAliasDeclSyntax.self)
        }
    }
#endif
