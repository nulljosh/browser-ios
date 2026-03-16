import SwiftUI

struct ReaderView: View {
    @Environment(AppState.self) private var appState
    @State private var fontSize: Double = 18
    @State private var backgroundColor = ReaderBackground.white

    enum ReaderBackground: String, CaseIterable {
        case white = "White"
        case sepia = "Sepia"
        case dark = "Dark"

        var bgColor: Color {
            switch self {
            case .white: return .white
            case .sepia: return Color(red: 0.96, green: 0.93, blue: 0.87)
            case .dark: return Color(red: 0.12, green: 0.12, blue: 0.14)
            }
        }

        var textColor: Color {
            switch self {
            case .white: return .black
            case .sepia: return Color(red: 0.3, green: 0.2, blue: 0.1)
            case .dark: return .white
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            content
        }
        .background(backgroundColor.bgColor)
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Text("Reader Mode")
                .font(.headline)

            Spacer()

            HStack(spacing: 6) {
                Button {
                    fontSize = max(12, fontSize - 2)
                } label: {
                    Image(systemName: "textformat.size.smaller")
                }

                Text("\(Int(fontSize))pt")
                    .font(.caption)
                    .frame(width: 32)

                Button {
                    fontSize = min(32, fontSize + 2)
                } label: {
                    Image(systemName: "textformat.size.larger")
                }
            }

            Picker("", selection: $backgroundColor) {
                ForEach(ReaderBackground.allCases, id: \.self) { bg in
                    Text(bg.rawValue).tag(bg)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 160)

            Button {
                appState.showReaderMode = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let title = appState.readerTitle {
                    Text(title)
                        .font(.system(size: fontSize * 1.6, weight: .bold, design: .serif))
                        .foregroundStyle(backgroundColor.textColor)
                }

                if let body = appState.readerContent {
                    Text(body)
                        .font(.system(size: fontSize, design: .serif))
                        .foregroundStyle(backgroundColor.textColor)
                        .lineSpacing(fontSize * 0.5)
                } else {
                    Text("Could not extract article content.")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    static let extractionScript = """
    (() => {
        const article = document.querySelector('article') || document.querySelector('[role="main"]') || document.body;
        const title = document.querySelector('h1')?.innerText || document.title;

        const clone = article.cloneNode(true);
        const removeTags = ['script', 'style', 'nav', 'footer', 'header', 'aside', 'iframe', 'form'];
        removeTags.forEach(tag => {
            clone.querySelectorAll(tag).forEach(el => el.remove());
        });

        const paragraphs = [];
        clone.querySelectorAll('p, h2, h3, h4, li, blockquote').forEach(el => {
            const text = el.innerText.trim();
            if (text.length > 20) {
                paragraphs.push(text);
            }
        });

        return JSON.stringify({ title: title, content: paragraphs.join('\\n\\n') });
    })();
    """
}
