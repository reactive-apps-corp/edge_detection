import WeScan
import Flutter
import Foundation

final class HomeViewController: UIViewController {
    private var cameraController: ImageScannerController!
    private var _result: FlutterResult?
    private var saveTo: String
    private var canUseGallery: Bool
    
    init(saveTo: String, canUseGallery: Bool, result: @escaping FlutterResult) {
        self.saveTo = saveTo
        self.canUseGallery = canUseGallery
        self._result = result
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCameraController()
        if canUseGallery { setupSelectPhotoButton() }
    }
    
    private func setupCameraController() {
        cameraController = ImageScannerController()
        cameraController.imageScannerDelegate = self
        cameraController.modalPresentationStyle = .fullScreen
        
        if #available(iOS 13.0, *) {
            cameraController.overrideUserInterfaceStyle = .dark
            cameraController.view.backgroundColor = .black
        }
        
        addChildСontroller(cameraController)
    }
    
    private func addChildСontroller(_ controller: UIViewController) {
        addChild(controller)
        view.addSubview(controller.view)
        controller.view.frame = view.bounds
        controller.didMove(toParent: self)
    }
    
    private lazy var selectPhotoButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "gallery", in: Bundle(for: SwiftEdgeDetectionPlugin.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(selectPhoto), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private func setupSelectPhotoButton() {
        view.addSubview(selectPhotoButton)
        NSLayoutConstraint.activate([
            selectPhotoButton.widthAnchor.constraint(equalToConstant: 44),
            selectPhotoButton.heightAnchor.constraint(equalToConstant: 44),
            selectPhotoButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: selectPhotoButton.bottomAnchor, constant: 22)
        ])
    }
    
    @objc private func selectPhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.modalPresentationStyle = .fullScreen
        
        DispatchQueue.main.async {
            self.present(imagePicker, animated: true)
        }
    }

    private func saveImage(image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else { return }
        
        let fileURL = URL(fileURLWithPath: self.saveTo)
        
        let fileManager = FileManager.default
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            try data.write(to: fileURL)
        } catch {
            print("Error saving image: \(error.localizedDescription)")
        }
    }
    
    private func hideSelectButton() {
        selectPhotoButton.isHidden = true
    }
}

extension HomeViewController: ImageScannerControllerDelegate {
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        hideSelectButton()
        _result?(false)
        dismiss(animated: true)
    }
    
    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
        hideSelectButton()
        saveImage(image: results.doesUserPreferEnhancedScan ? results.enhancedScan!.image : results.croppedScan.image)
        _result?(true)
        dismiss(animated: true)
    }
    
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        hideSelectButton()
        _result?(false)
        dismiss(animated: true)
    }
}

extension HomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) {
            guard let image = info[.originalImage] as? UIImage else { return }
            DispatchQueue.main.async {
                self.hideSelectButton()
                self.cameraController.useImage(image: image)
            }
        }
    }
}