import AppKit
import Carbon
import Foundation
import WebKit


class GoogleViewer: WKWebView {
  func initBlockRules() {
    let blockRules = [[
      "trigger": ["url-filter": ".*"],
      "action": [
        "type": "css-display-none",
        "selector": [
          "header",
          "footer",
          "#sfooter",
          "#botstuff"].joined(separator: ", ")]]]

    let jsonData = try! JSONSerialization.data(withJSONObject: blockRules)
    let blockRulesJsonString = String(data: jsonData, encoding: .utf8)!

    WKContentRuleListStore.default().compileContentRuleList(
      forIdentifier: "ContentBlockingRules",
      encodedContentRuleList: blockRulesJsonString
    ) { (contentRuleList, error) in
      self.configuration.userContentController.add(contentRuleList!)
    }
  }
}


// Floating webview based on: https://github.com/Qusic/Loaf
class AppDelegate: NSObject, NSApplicationDelegate {
  var minHeight: CGFloat = 600
  let maxWebviewWidth: CGFloat = 300

  let screen: NSScreen = NSScreen.main!
  lazy var screenWidth: CGFloat = screen.frame.width
  lazy var screenHeight: CGFloat = screen.frame.height

  var alfredFrame: NSRect = NSRect()

  let alfredWatcher: AlfredWatcher = AlfredWatcher()

  lazy var window: NSWindow = {
    let window = NSWindow(
      contentRect: .zero,
      styleMask: [.borderless, .fullSizeContentView],
      backing: .buffered,
      defer: false,
      screen: screen)
    window.level = .floating
    window.collectionBehavior = [
      .canJoinAllSpaces,
      .stationary,
      .fullScreenAuxiliary
    ]

    // weird: without the following line
    // the webview just doesn't load!
    window.titlebarAppearsTransparent = true

    // Need this backgrund view gimickry because
    // if we don't have .titled for the window,
    // window.backgroundColor seems to
    // have no effect at all, and we don't want titled because
    // we don't want window border
    let windowBkg = NSView(frame: NSRect.init())
    window.contentView = windowBkg

    return window
  }()

  lazy var webview: WKWebView = {
    let configuration = WKWebViewConfiguration()
    let webview = GoogleViewer(frame: .zero, configuration: configuration)

    webview.initBlockRules()
    webview.customUserAgent = [
      "Mozilla/5.0 (Linux; Android 8.0; Pixel 2 Build/OPD3.170816.012)",
      "AppleWebKit/537.36 (KHTML, like Gecko)",
      "Chrome/85.0.4183.121",
      "Mobile Safari/537.36"
    ].joined(separator: " ")

    let startUrl = URL(string: "https://www.google.com/search?cs=1&q=start")!
    webview.load(URLRequest(url: startUrl))

    return webview
  }()

  func searchGoogle(_ query: String) {
    self.webview.evaluateJavaScript(
      """
      document.querySelector("input[name='q']").value = "\(query)";
      document.querySelector('form').submit();
      """,
      completionHandler: { (out, err) in
        log("\(out)")
        log("\(err)")
      })
    showWindow(alfred: alfredFrame)
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    window.contentView?.addSubview(webview)
    alfredWatcher.start(
      onAlfredWindowDestroy: {
        self.window.orderOut(self)
      },
      setAlfredFrame: { self.alfredFrame = $0 }
    )
  }

  func showWindow(alfred: CGRect) {
    window.setFrame(
      NSRect(
        x: alfred.minX,
        y: alfred.maxY - minHeight,
        width: alfred.width,
        height: minHeight),
      display: false
    )
    webview.setFrameOrigin(NSPoint(x: 0, y: 0))
    webview.setFrameSize(
      NSSize(width: alfred.width, height: minHeight - alfred.height))
    window.makeKeyAndOrderFront(self)
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
      log("\(url)")
      let param = url.queryParameters
      switch url.host {
      case "update":
        window.contentView?.backgroundColor = NSColor.fromHexString(
          hex: param["bkgColor"]!,
          alpha: 1
        )
        searchGoogle(param["rawQuery"]!)
      default:
        break
      }
    }
  }
}


autoreleasepool {
  let app = NSApplication.shared
  let delegate = AppDelegate()
  app.setActivationPolicy(.accessory)
  app.delegate = delegate
  app.run()
}
