#if Swift
    import File_System
    import Process

    extension Highlighting.Swift {
        struct Reference: Sendable, Equatable {
            var kind: Kind
        }
    }

    extension Highlighting.Swift.Reference {
        static func resolve(_ shown: Highlighting.Swift.File, in project: [Highlighting.Swift.File]) -> [Position: Self] {
            let directory: File_System::File.Path
            do throws(File_System::File.Path.Temporary.Error) {
                directory = try File_System::File.Path.Temporary.unique(prefix: "highlighting-")
            } catch {
                return [:]
            }
            defer { remove(directory) }
            guard create(directory), project.allSatisfy({ write($0.text, to: $0.name, in: directory) }) else { return [:] }
            let sdk = run(["--sdk", "macosx", "--show-sdk-path"], in: directory).stdout.split(whereSeparator: \.isNewline).first.map(Swift::String.init) ?? ""
            let target = run(["swiftc", "-print-target-info"], in: directory).stdout
            let dump = run(["swiftc", "-dump-ast", "-sdk", sdk] + project.map(\.name), in: directory)
            var interfaces = Highlighting.Swift.Interfaces(sdk: sdk, triple: value(after: "\"moduleTriple\": \"", until: "\"", in: Substring(target)) ?? "")
            var references: [Position: Self] = [:]
            for line in (dump.stdout + dump.stderr).split(separator: "\n") {
                guard let decl = value(after: "decl=\"", until: "\"", in: line), !decl.contains(".self@"),
                    let location = value(after: "location=\(shown.name):", until: " ", in: line)
                else { continue }
                let parts = location.split(separator: ":").compactMap { Int($0) }
                guard parts.count == 2 else { continue }
                let position = Position(line: parts[0], column: parts[1])
                if references[position] == nil { references[position] = Self(kind: kind(of: decl, interfaces: &interfaces)) }
            }
            return references
        }

        static func kind(of decl: Swift::String, interfaces: inout Highlighting.Swift.Interfaces) -> Kind {
            guard let marker = decl.firstRange(of: ".(file).") else { return .local }
            let module = Swift::String(decl[..<marker.lowerBound])
            var path = Swift::String(decl[marker.upperBound...])
            if let with = path.firstRange(of: " [with") { path = Swift::String(path[..<with.lowerBound]) }
            if let at = path.firstIndex(of: "@") { path = Swift::String(path[..<at]) }
            if module == "main" { return path.contains("<anonymous>") || path.contains("closure") ? .local : .project }
            return .system(emitted: interfaces.emitted(module: module, path: path))
        }

        static func value(after start: Swift::String, until end: Character, in line: Substring) -> Swift::String? {
            guard let range = line.firstRange(of: start) else { return nil }
            let rest = line[range.upperBound...]
            return Swift::String(rest.prefix { $0 != end })
        }

        static func run(_ arguments: [Swift::String], in directory: File_System::File.Path) -> (stdout: Swift::String, stderr: Swift::String) {
            let configuration = Process::Process.Spawn.Configuration(
                executable: "/usr/bin/xcrun",
                arguments: arguments,
                stdout: .pipe,
                stderr: .pipe,
                directory: directory
            )
            do throws(Process::Process.Error) {
                let output = try Process::Process.Spawn.run(configuration)
                return (Swift::String(decoding: output.stdout ?? [], as: UTF8.self), Swift::String(decoding: output.stderr ?? [], as: UTF8.self))
            } catch {
                return ("", "")
            }
        }

        static func create(_ directory: File_System::File.Path) -> Bool {
            do throws(File_System::File.System.Create.Directory.Error) {
                try File_System::File.Directory(directory).create.recursive()
                return true
            } catch {
                return false
            }
        }

        static func remove(_ directory: File_System::File.Path) {
            do throws(File_System::File.System.Delete.Error) {
                try File_System::File.Directory(directory).delete.recursive()
            } catch {
                return
            }
        }

        static func write(_ text: Swift::String, to name: Swift::String, in directory: File_System::File.Path) -> Bool {
            do throws(File_System::File.Path.Error) {
                let path = directory.appending(try File_System::File.Path(name))
                do throws(File_System::File.System.Write.Atomic.Error) {
                    try File_System::File(path).write.atomic(contentsOf: Array(text.utf8).map(Byte.init(bitPattern:)))
                    return true
                } catch {
                    return false
                }
            } catch {
                return false
            }
        }

        static func read(_ file: Swift::String) -> Swift::String {
            do throws(File_System::File.Path.Error) {
                let path = try File_System::File.Path(file)
                do throws(File_System::File.System.Read.Full.Error) {
                    let bytes = try File_System::File(path).read.ifExists() ?? []
                    return Swift::String(decoding: bytes.map(\.bitPattern), as: UTF8.self)
                } catch {
                    return ""
                }
            } catch {
                return ""
            }
        }
    }
#endif
