#if Swift
    import Foundation
    import Highlighting_Swift
    import Testing

    @Suite struct `Highlight Tests` {
        @Test func `every word of Harbor's ContentView has the role Xcode 27.2 draws it in`() {
            let lines = Highlighting.Swift.lines(of: Harbor.content, in: Harbor.project)
            let words = lines.enumerated().flatMap { line in
                line.element.filter { $0.text.contains { !$0.isWhitespace } }.map { "\(line.offset + 1) \($0.text) \($0.role)" }
            }
            #expect(
                words == [
                    "1 import keyword", "1 SwiftUI plain",
                    "3 struct keyword", "3 ContentView declarationType", "3 : plain", "3 View systemType", "3 { plain",
                    "4 @ systemMember", "4 State systemMember", "4 private keyword", "4 var keyword", "4 tides declarationOther", "4 : plain",
                    "4 [ plain", "4 Tide projectType", "4 ] plain", "4 = plain", "4 [ plain", "4 ] plain",
                    "6 var keyword", "6 body declarationOther", "6 : plain", "6 some keyword", "6 View systemType", "6 { plain",
                    "7 List systemType", "7 ( plain", "7 tides projectMember", "7 ) plain", "7 { plain", "7 tide plain", "7 in keyword",
                    "8 TideRow projectType", "8 ( plain", "8 tide projectLabel", "8 : plain", "8 tide plain", "8 ) plain",
                    "9 } plain",
                    "10 . plain", "10 navigationTitle systemMember", "10 ( plain", "10 \" string", "10 Harbor string", "10 \" string", "10 ) plain",
                    "11 . plain", "11 task plain", "11 { plain", "11 tides projectMember", "11 = plain", "11 await keyword", "11 Tide projectType",
                    "11 . plain", "11 today projectMember", "11 ( plain", "11 ) plain", "11 } plain",
                    "12 } plain",
                    "13 } plain",
                ]
            )
        }

        @Test func `the lines keep every character of the file`() {
            let lines = Highlighting.Swift.lines(of: Harbor.content, in: Harbor.project)
            #expect(lines.map { $0.map(\.text).joined() }.joined(separator: "\n") == Harbor.content.text)
        }
    }

    @MainActor @Suite struct `Resolution Tests` {
        @Test func `resolving references waits for the compiler without running the main run loop`() {
            var ran = false
            RunLoop.main.perform { ran = true }
            _ = Highlighting.Swift.lines(of: Harbor.content, in: Harbor.project)
            #expect(!ran)
        }
    }
#endif
