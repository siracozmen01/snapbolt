import AppKit
import ScreenCaptureKit
import SnapboltCore

/// Freezes displays with ScreenCaptureKit, before any Snapbolt UI is shown.
public struct ScreenCaptureKitCapturer: ScreenCapturing {
    /// Creates a capturer.
    public init() {}

    /// Captures the displays in `scope` at full resolution, without the cursor, plus the visible windows.
    /// - Throws: ``CaptureError``.
    public func freezeDisplays(_ scope: CaptureScope) async throws -> FrozenScreens {
        guard CGPreflightScreenCaptureAccess() else { throw CaptureError.permissionDenied }
        let geometries = try await targetGeometries(for: scope)
        let content = try await Self.mapErrors { try await SCShareableContent.current }
        var displays: [FrozenDisplay] = []
        // Displays are captured one after another: SCDisplay is not Sendable, and one capture takes a
        // few tens of milliseconds.
        for geometry in geometries {
            guard let display = content.displays.first(where: { $0.displayID == geometry.id.rawValue }) else {
                continue
            }
            displays.append(try await Self.capture(display, geometry: geometry))
        }
        guard !displays.isEmpty else { throw CaptureError.noDisplays }
        let windows = WindowListReader.windows(excludingProcess: ProcessInfo.processInfo.processIdentifier)
        return FrozenScreens(displays: displays, windows: windows)
    }

    private func targetGeometries(for scope: CaptureScope) async throws -> [ScreenGeometry] {
        let (screens, cursor) = await MainActor.run {
            (DisplayScaleReader.screens(), DisplayScaleReader.cursorLocationInGlobalPoints())
        }
        switch scope {
        case .allDisplays:
            return screens
        case .displayUnderCursor:
            guard let screen = screens.first(where: { $0.frameInGlobalPoints.contains(cursor) }) ?? screens.first
            else { throw CaptureError.noDisplays }
            return [screen]
        }
    }

    private static func capture(_ display: SCDisplay, geometry: ScreenGeometry) async throws -> FrozenDisplay {
        let configuration = SCStreamConfiguration()
        configuration.width = Int(geometry.frameInGlobalPoints.width * geometry.scale)
        configuration.height = Int(geometry.frameInGlobalPoints.height * geometry.scale)
        configuration.showsCursor = false
        configuration.captureResolution = .best
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let image = try await mapErrors {
            try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
        }
        return FrozenDisplay(
            id: geometry.id, image: image, frameInGlobalPoints: geometry.frameInGlobalPoints, scale: geometry.scale)
    }

    private static func mapErrors<Value>(_ operation: () async throws -> Value) async throws -> Value {
        do {
            return try await operation()
        } catch let error as NSError where isUserDeclined(error) {
            throw CaptureError.permissionDenied
        } catch {
            logger.error("ScreenCaptureKit failed: \(error.localizedDescription, privacy: .public)")
            throw CaptureError.captureFailed(error.localizedDescription)
        }
    }

    private static func isUserDeclined(_ error: NSError) -> Bool {
        error.domain == SCStreamErrorDomain && error.code == SCStreamError.userDeclined.rawValue
    }
}
