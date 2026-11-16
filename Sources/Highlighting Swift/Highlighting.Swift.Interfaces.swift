#if Swift
    import SwiftParser
    import SwiftSyntax

    extension Highlighting.Swift {
        struct Interfaces {
            let sdk: String
            let triple: String
            var texts: [String: String] = [:]
        }
    }

    extension Highlighting.Swift.Interfaces {
        mutating func emitted(module: String, path: String) -> Bool { Self.emitted(&self, module: module, path: path) }

        static func emitted(_ interfaces: inout Self, module: String, path: String) -> Bool {
            guard let dot = Self.split(path) else { return false }
            let context = String(path[..<dot]).replacing(" extension", with: "")
            let member = String(path[path.index(after: dot)...])
            let name = String(member.prefix { $0 != "(" })
            let labels = member.contains("(") ? member.drop { $0 != "(" }.dropFirst().dropLast().split(separator: ":").map(String.init) : nil
            let tree = Parser.parse(source: Self.declarations(&interfaces, in: module, naming: name))
            return tree.tokens(viewMode: .sourceAccurate).contains { token in
                guard token.text == name, let decl = token.parent else { return false }
                if let function = decl.as(FunctionDeclSyntax.self) {
                    return function.name == token && labels == function.signature.parameterClause.parameters.map(\.firstName.text)
                        && Self.extends(Syntax(function), context) && Self.emitted(function.attributes)
                }
                if let pattern = decl.as(IdentifierPatternSyntax.self), labels == nil,
                    let variable = Self.ancestor(of: pattern, VariableDeclSyntax.self)
                {
                    return Self.extends(Syntax(variable), context) && Self.emitted(variable.attributes)
                }
                return false
            }
        }

        static func declarations(_ interfaces: inout Self, in module: String, naming name: String) -> String {
            let text: String
            if let cached = interfaces.texts[module] {
                text = cached
            } else {
                let directory = "\(interfaces.sdk)/System/Library/Frameworks/\(module).framework/Modules/\(module).swiftmodule"
                let read = Highlighting.Swift.Reference.read("\(directory)/\(interfaces.triple).swiftinterface")
                if read.isEmpty, interfaces.triple.hasPrefix("arm64-") {
                    let triple = "arm64e-\(interfaces.triple.dropFirst("arm64-".count))"
                    text = Highlighting.Swift.Reference.read("\(directory)/\(triple).swiftinterface")
                } else {
                    text = read
                }
                interfaces.texts[module] = text
            }
            var chunks: [[Substring]] = []
            var previous: Substring = ""
            for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
                let top = line.first.map { !$0.isWhitespace && $0 != "}" } ?? false
                if top && !previous.hasPrefix("@") || chunks.isEmpty { chunks.append([]) }
                if let last = chunks.indices.last { chunks[last].append(line) }
                previous = line
            }
            let mentions = ["func \(name)(", "func \(name)<", "var \(name):", "let \(name):"]
            return chunks.filter { chunk in chunk.contains { line in mentions.contains { line.contains($0) } } }
                .map { $0.joined(separator: "\n") }
                .joined(separator: "\n")
        }

        static func split(_ path: String) -> String.Index? {
            var depth = 0
            var last: String.Index?
            for index in path.indices {
                switch path[index] {
                case "(": depth += 1
                case ")": depth -= 1
                case "." where depth == 0: last = index
                default: break
                }
            }
            return last
        }

        static func extends(_ decl: Syntax, _ context: String) -> Bool {
            let type = context.split(whereSeparator: { $0 == "." || $0 == ":" }).last.map(String.init) ?? context
            var node = decl.parent
            while let current = node {
                if let extensionDecl = current.as(ExtensionDeclSyntax.self) {
                    return extensionDecl.extendedType.trimmedDescription.split(whereSeparator: { $0 == "." || $0 == ":" }).last.map(String.init) == type
                }
                node = current.parent
            }
            return false
        }

        static func emitted(_ attributes: AttributeListSyntax) -> Bool {
            attributes.contains { element in
                guard let attribute = element.as(AttributeSyntax.self) else { return false }
                let name = attribute.attributeName.trimmedDescription
                return name == "_alwaysEmitIntoClient" || name == "export"
            }
        }

        static func ancestor<T: SyntaxProtocol>(of syntax: some SyntaxProtocol, _ type: T.Type) -> T? {
            var node = syntax.parent
            while let current = node {
                if let match = current.as(type) { return match }
                node = current.parent
            }
            return nil
        }
    }
#endif
