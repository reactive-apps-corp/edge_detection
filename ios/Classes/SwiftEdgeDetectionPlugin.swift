import Flutter
import UIKit
import WeScan

public class SwiftEdgeDetectionPlugin: NSObject, FlutterPlugin, UIApplicationDelegate {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "edge_detection", binaryMessenger: registrar.messenger())
        let instance = SwiftEdgeDetectionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    private static func topViewController() -> UIViewController? {
        var top = UIApplication.shared.delegate?.window??.rootViewController
        if top == nil, #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
            top = (scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first)?.rootViewController
        }
        while let presented = top?.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        return top
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing parameters", details: nil))
            return
        }
        
        let canUseGallery = args["can_use_gallery"] as? Bool ?? false
        let multipleScan = args["multiple_scan"] as? Bool ?? false
        
        guard let viewController = Self.topViewController()
        else {
            result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find root view controller", details: nil))
            return
        }
        
        let destinationVC = HomeViewController(canUseGallery: canUseGallery, multipleScan: multipleScan, result: result)
        destinationVC.modalPresentationStyle = .fullScreen
        
        DispatchQueue.main.async {
            viewController.present(destinationVC, animated: true)
        }
    }
}
