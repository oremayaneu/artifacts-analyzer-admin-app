import SwiftUI
import WebKit
import SwiftSoup

struct ScrapingCharacter: UIViewRepresentable {
    let url: URL
    let onLoaded: (String, [String], [String]) -> Void
    let onLoading: () -> Void
    let onError: () -> Void
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: ScrapingCharacter
        init(parent: ScrapingCharacter) { self.parent = parent }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let js = "document.documentElement.outerHTML"

            webView.evaluateJavaScript(js) { result, error in
                if let html = result as? String {
                    do {
                        let doc: Document = try SwiftSoup.parse(html)
                        
                        let texts: Elements = try doc.select("div.ProseMirror p")
                        let tags: Elements = try doc.select("div.c-entry-tag-item.active.genshin")
                        let parameters: Elements = try doc.select("td.m-d-ascension-td")
                        if let element = try doc.select("meta[property=og:image]").first() {
                            let content = try element.attr("content")
                            print(content)
                        }
                        
                        if texts.count >= 2 && tags.count >= 1 && parameters.count >= 80 {
                            let name = try texts[1].text()
                            
                            var tagTexts: [String] = []
                            for tag in tags {
                                let tagText = try tag.text()
                                tagTexts.append(tagText)
                            }
                            
                            var parameterTexts: [String] = []
                            let indices = [72, 74, 76, 78]
                            for index in indices {
                                let parameterText = try parameters[index].text()
                                parameterTexts.append(parameterText)
                            }
                            
                            self.parent.onLoaded(name, tagTexts, parameterTexts)
                        } else {
                            self.parent.onError()
                        }
                    } catch {
                        self.parent.onError()
                        print("SwiftSoupパースエラー:", error)
                    }
                } else {
                    self.parent.onError()
                    print("HTML取得エラー:", error?.localizedDescription ?? "不明")
                }
                // loading状態を解除
                self.parent.onLoading()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
