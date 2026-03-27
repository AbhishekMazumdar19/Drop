import Foundation
import FirebaseStorage
import UIKit

final class MediaUploadService {

    static let shared = MediaUploadService()
    private init() {}

    private let storage = Storage.storage()

    // MARK: - Upload Profile Image

    func uploadProfileImage(_ image: UIImage, userId: String) async throws -> URL {
        let path = StoragePaths.profileImage(userId: userId)
        return try await upload(image: image, path: path)
    }

    // MARK: - Upload Drop Image

    func uploadDropImage(_ image: UIImage, userId: String) async throws -> URL {
        let responseId = UUID().uuidString
        let path = StoragePaths.dropImage(userId: userId, responseId: responseId)
        return try await upload(image: image, path: path)
    }

    // MARK: - Core Upload

    private func upload(image: UIImage, path: String) async throws -> URL {
        guard let data = image.jpegData(compressionQuality: DropConfig.imageCompressionQuality) else {
            throw ServiceError.uploadFailed
        }

        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(data, metadata: metadata)
        let downloadURL = try await ref.downloadURL()
        return downloadURL
    }

    // MARK: - Delete Image

    func deleteImage(at path: String) async {
        let ref = storage.reference().child(path)
        try? await ref.delete()
    }
}

// MARK: - UIImage Extensions
extension UIImage {
    /// Resize to a max dimension while preserving aspect ratio
    func resized(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        return UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    func preparedForUpload() -> UIImage {
        resized(maxDimension: 1200)
    }
}
