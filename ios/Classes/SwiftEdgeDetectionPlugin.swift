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
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let saveTo = args["save_to"] as? String
        else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing parameters", details: nil))
            return
        }
        
        let canUseGallery = args["can_use_gallery"] as? Bool ?? false
        guard let viewController = UIApplication.shared.delegate?.window??.rootViewController
        else {
            result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find root view controller", details: nil))
            return
        }
        
        let destinationVC = HomeViewController(saveTo: saveTo, canUseGallery: canUseGallery, result: result)
        destinationVC.modalPresentationStyle = .fullScreen
        
        DispatchQueue.main.async {
            viewController.present(destinationVC, animated: true)
        }
    }
}
