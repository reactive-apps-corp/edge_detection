import WeScan
import Flutter
import Foundation

final class HomeViewController: UIViewController {
    private var cameraController: ImageScannerController!
    private var _result: FlutterResult?
    private var canUseGallery: Bool
    private var multipleScan: Bool
    private var scannedImages: [String] = [] // Array of scanned image paths

    init(canUseGallery: Bool, multipleScan: Bool, result: @escaping FlutterResult) {
        self.canUseGallery = canUseGallery
        self.multipleScan = multipleScan
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

    private func saveImage(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else { return nil }

        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
        let fileName = "scan_\(UUID().uuidString).jpg"
        let fileURL = directory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving image: \(error.localizedDescription)")
            return nil
        }
    }

    private func hideSelectButton() {
        selectPhotoButton.isHidden = true
    }

    private func showSelectButtonIfNeeded() {
        if canUseGallery {
            selectPhotoButton.isHidden = false
        }
    }

    private func askForAnotherScan(scanner: ImageScannerController) {
        let alert = UIAlertController(title: "Scan another receipt?", message: nil, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
            self.showSelectButtonIfNeeded()
            scanner.resetScanner()
        })

        alert.addAction(UIAlertAction(title: "No", style: .cancel) { _ in
            scanner.dismiss(animated: true) {
                self._result?(self.scannedImages) // Return array of scanned image paths
            }
        })

        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
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

        if let imagePath = saveImage(image: results.doesUserPreferEnhancedScan ? results.enhancedScan!.image : results.croppedScan.image) {
            scannedImages.append(imagePath)
        }

        if multipleScan {
            askForAnotherScan(scanner: scanner)
        } else {
            scanner.dismiss(animated: true) {
                self._result?(self.scannedImages)
            }
        }
    }

    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        hideSelectButton()
        _result?(self.scannedImages)
        dismiss(animated: true)
    }
    
    func imageScannerControllerMoveEdit(_ scanner: ImageScannerController) {
        hideSelectButton()
    }
    
    func imageScannerControllerViewWillAppear(_ scanner: ImageScannerController) {
        showSelectButtonIfNeeded()
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
