import SwiftUI
import PhotosUI
import AVFoundation
import UIKit

// MARK: - ImagePicker (Unified: Library + Camera)
struct ImagePicker: UIViewControllerRepresentable {

    enum PickerSource { case library, camera }

    @Binding var selectedImage: UIImage?
    var source: PickerSource = .library
    var onDismiss: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> UIViewController {
        switch source {
        case .library:
            return makePHPicker(context: context)
        case .camera:
            return makeCameraController(context: context)
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    // MARK: Photos Library
    private func makePHPicker(context: Context) -> UIViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    // MARK: Camera
    private func makeCameraController(context: Context) -> UIViewController {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            // Fallback to library on simulator
            return makePHPicker(context: context)
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Coordinator
    final class Coordinator: NSObject, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        let parent: ImagePicker

        init(_ parent: ImagePicker) { self.parent = parent }

        // PHPickerViewController
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let result = results.first else {
                parent.onDismiss?()
                return
            }
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                DispatchQueue.main.async {
                    self?.parent.selectedImage = object as? UIImage
                    self?.parent.onDismiss?()
                }
            }
        }

        // UIImagePickerController
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            picker.dismiss(animated: true)
            parent.selectedImage = info[.originalImage] as? UIImage
            parent.onDismiss?()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            parent.onDismiss?()
        }
    }
}

// MARK: - CameraPermissionView
/// Displayed when camera access is denied
struct CameraPermissionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(LinearGradient.dropFireGradient)

            Text("Camera Access Required")
                .font(DROPFont.headline())
                .foregroundColor(.white)

            Text("Allow camera access to complete your Drop.")
                .font(DROPFont.body())
                .foregroundColor(.dropTextSecondary)
                .multilineTextAlignment(.center)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(DROPFont.headline(16))
            .foregroundColor(.dropBlack)
            .primaryButton()
            .padding(.horizontal, 32)
        }
        .padding()
    }
}
