import Metal
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MILESTONE 7: Frame export pipeline
// Converts Metal textures to CGImage and writes to disk at 60 FPS

class FrameExporter {

    private let device: MTLDevice
    private let outputPath: URL
    private let colorSpace: CGColorSpace

    // Reusable buffer for texture data
    private var pixelBuffer: UnsafeMutableRawPointer?
    private var bufferSize: Int = 0

    init?(device: MTLDevice) {
        self.device = device

        // Output directory: ~/.config/iTerm2ShaderCLI/
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("iTerm2ShaderCLI")

        // Create directory if needed
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)

        self.outputPath = configDir.appendingPathComponent("frame.png")
        // Use sRGB color space for accurate color reproduction
        self.colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

        print("FrameExporter initialized - Output: \(outputPath.path)")
    }

    deinit {
        if let buffer = pixelBuffer {
            buffer.deallocate()
        }
    }

    // Export Metal texture to PNG file
    // Returns true if export succeeded
    func exportFrame(texture: MTLTexture) -> Bool {
        let width = texture.width
        let height = texture.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let totalBytes = height * bytesPerRow

        // Allocate buffer if needed
        if pixelBuffer == nil || bufferSize < totalBytes {
            if let oldBuffer = pixelBuffer {
                oldBuffer.deallocate()
            }
            pixelBuffer = UnsafeMutableRawPointer.allocate(byteCount: totalBytes, alignment: MemoryLayout<UInt8>.alignment)
            bufferSize = totalBytes
        }

        guard let buffer = pixelBuffer else { return false }

        // Read texture data into CPU buffer
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.getBytes(buffer, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)

        // Brighten the image to compensate for iTerm2's darkening
        // iTerm2 blends background images which makes them darker
        brightenBuffer(buffer: buffer, totalBytes: totalBytes)

        // Create CGImage from buffer
        guard let dataProvider = CGDataProvider(
            dataInfo: nil,
            data: buffer,
            size: totalBytes,
            releaseData: { _, _, _ in }  // We manage the buffer lifecycle
        ) else {
            print("ERROR: Failed to create CGDataProvider")
            return false
        }

        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            print("ERROR: Failed to create CGImage")
            return false
        }

        // Write directly to output file (atomic writes cause issues with temp file cleanup)
        guard let destination = CGImageDestinationCreateWithURL(outputPath as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            print("ERROR: Failed to create image destination")
            return false
        }

        CGImageDestinationAddImage(destination, cgImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            print("ERROR: Failed to finalize image destination")
            return false
        }

        return true
    }

    // Brightness adjustment removed - use iTerm2's native blending settings instead
    private func brightenBuffer(buffer: UnsafeMutableRawPointer, totalBytes: Int) {
        // No brightness adjustment - original colors preserved
        // User can adjust brightness via iTerm2 Preferences:
        // - Background Image Blending
        // - Window Transparency
        // - Background Color settings
    }
}
