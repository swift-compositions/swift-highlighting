#if Swift
    import Highlighting_Swift

    enum Harbor {}

    extension Harbor {
        static let content = Highlighting.Swift.File(
            name: "ContentView.swift",
            text: """
                import SwiftUI

                struct ContentView: View {
                    @State private var tides: [Tide] = []

                    var body: some View {
                        List(tides) { tide in
                            TideRow(tide: tide)
                        }
                        .navigationTitle("Harbor")
                        .task { tides = await Tide.today() }
                    }
                }

                """
        )

        static let project = [
            content,
            Highlighting.Swift.File(
                name: "Tide.swift",
                text: """
                    import Foundation

                    struct Tide: Identifiable {
                        let id = UUID()
                        var height: Double

                        static func today() async -> [Tide] { [] }
                    }

                    """
            ),
            Highlighting.Swift.File(
                name: "TideRow.swift",
                text: """
                    import SwiftUI

                    struct TideRow: View {
                        let tide: Tide

                        var body: some View { Text(tide.height, format: .number) }
                    }

                    """
            ),
            Highlighting.Swift.File(
                name: "HarborApp.swift",
                text: """
                    import SwiftUI

                    @main
                    struct HarborApp: App {
                        var body: some Scene { WindowGroup { ContentView() } }
                    }

                    """
            ),
        ]
    }
#endif
