import Cocoa
import CoreFoundation

typealias Dict = [String: Any]

class AlfredWatcher {
  var onDestroy: (() -> Void)!
  var setAlfredFrame: ((NSRect)-> Void)!

  func start(
    onAlfredWindowDestroy: @escaping () -> Void,
    setAlfredFrame: @escaping (NSRect) -> Void
  ) {
    self.onDestroy = onAlfredWindowDestroy
    self.setAlfredFrame = setAlfredFrame

    DistributedNotificationCenter.default().addObserver(
      self,
      selector: #selector(handleAlfredNotification),
      name: NSNotification.Name(rawValue: "alfred.presssecretary"),
      object: nil,
      suspensionBehavior: .deliverImmediately
    )
  }

  @objc func handleAlfredNotification(notification: NSNotification) {
    // log("\(notification)")
    let notif = notification.userInfo! as! Dict
    let notifType = notif["announcement"] as! String
    if (notifType == "window.hidden") {
      self.onDestroy()
    } else if (notifType == "selection.changed") {
      let frame = NSRectFromString(notif["windowframe"] as! String)
      self.setAlfredFrame(frame)
    }
  }
}
