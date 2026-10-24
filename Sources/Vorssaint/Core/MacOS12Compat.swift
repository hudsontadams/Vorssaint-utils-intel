// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import AVFoundation
import CoreAudio
import CoreImage
import CoreMedia
import EventKit
import Foundation
import QuartzCore
import ScreenCaptureKit

// MARK: - AppKit / EventKit / ScreenCaptureKit / CoreAudio Shims (Pre-macOS 14 SDK)

#if !compiler(>=5.9)

extension NSPopover {
    var hasFullSizeContent: Bool {
        get {
            guard responds(to: Selector(("hasFullSizeContent"))) else { return false }
            return (value(forKey: "hasFullSizeContent") as? Bool) ?? false
        }
        set {
            guard responds(to: Selector(("setHasFullSizeContent:"))) else { return }
            setValue(newValue, forKey: "hasFullSizeContent")
        }
    }
}

extension NSRunningApplication {
    @discardableResult
    func activate(from application: NSRunningApplication,
                  options: NSApplication.ActivationOptions = []) -> Bool {
        activate(options: options.union([.activateIgnoringOtherApps]))
    }
}

extension EKAuthorizationStatus {
    static var fullAccess: EKAuthorizationStatus { .authorized }
    static var writeOnly: EKAuthorizationStatus { EKAuthorizationStatus(rawValue: 4) ?? EKAuthorizationStatus(rawValue: -1)! }
}

extension EKEventStore {
    func requestFullAccessToEvents(completion: @escaping EKEventStoreRequestAccessCompletionHandler) {
        requestAccess(to: .event, completion: completion)
    }

    func requestFullAccessToEvents() async throws -> Bool {
        try await requestAccess(to: .event)
    }
}

enum SCCaptureResolutionType: Int, Sendable {
    case automatic = 0
    case best = 1
    case nominal = 2
}

extension SCStreamConfiguration {
    var captureResolution: SCCaptureResolutionType {
        get { .best }
        set {}
    }

    var preservesAspectRatio: Bool {
        get { true }
        set {}
    }

    private static var _shouldBeOpaqueKey: UInt8 = 0
    private static var _ignoreShadowsDisplayKey: UInt8 = 0
    private static var _ignoreShadowsSingleWindowKey: UInt8 = 0
    private static var _ignoreGlobalClipSingleWindowKey: UInt8 = 0

    var shouldBeOpaque: Bool {
        get { (objc_getAssociatedObject(self, &Self._shouldBeOpaqueKey) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &Self._shouldBeOpaqueKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var ignoreShadowsDisplay: Bool {
        get { (objc_getAssociatedObject(self, &Self._ignoreShadowsDisplayKey) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &Self._ignoreShadowsDisplayKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var ignoreShadowsSingleWindow: Bool {
        get { (objc_getAssociatedObject(self, &Self._ignoreShadowsSingleWindowKey) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &Self._ignoreShadowsSingleWindowKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var ignoreGlobalClipSingleWindow: Bool {
        get { (objc_getAssociatedObject(self, &Self._ignoreGlobalClipSingleWindowKey) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &Self._ignoreGlobalClipSingleWindowKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

extension SCContentFilter {
    var pointPixelScale: Float {
        Float(NSScreen.main?.backingScaleFactor ?? 2.0)
    }
}

enum SCScreenshotManager {
    private final class SingleFrameReceiver: NSObject, SCStreamOutput, @unchecked Sendable {
        private let lock = NSLock()
        private var continuation: CheckedContinuation<CGImage, Error>?
        private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

        init(continuation: CheckedContinuation<CGImage, Error>) {
            self.continuation = continuation
        }

        func finish(with result: Result<CGImage, Error>) {
            lock.lock()
            let pending = continuation
            continuation = nil
            lock.unlock()
            switch result {
            case .success(let image):
                pending?.resume(returning: image)
            case .failure(let error):
                pending?.resume(throwing: error)
            }
        }

        func stream(_ stream: SCStream,
                    didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
                    of outputType: SCStreamOutputType) {
            guard outputType == .screen,
                  sampleBuffer.isValid,
                  let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            let rect = CGRect(x: 0,
                              y: 0,
                              width: CVPixelBufferGetWidth(imageBuffer),
                              height: CVPixelBufferGetHeight(imageBuffer))
            guard rect.width > 0, rect.height > 0,
                  let cgImage = Self.ciContext.createCGImage(ciImage, from: rect) else { return }
            finish(with: .success(cgImage))
        }
    }

    static func captureImage(contentFilter: SCContentFilter,
                             configuration: SCStreamConfiguration) async throws -> CGImage {
        let stream = SCStream(filter: contentFilter, configuration: configuration, delegate: nil)
        let queue = DispatchQueue(label: "com.vorssaint.utils.scscreenshot-compat", qos: .userInitiated)
        let image: CGImage = try await withCheckedThrowingContinuation { continuation in
            let receiver = SingleFrameReceiver(continuation: continuation)
            do {
                try stream.addStreamOutput(receiver, type: .screen, sampleHandlerQueue: queue)
            } catch {
                receiver.finish(with: .failure(error))
                return
            }
            stream.startCapture { error in
                if let error {
                    receiver.finish(with: .failure(error))
                }
            }
            queue.asyncAfter(deadline: .now() + 1.5) {
                receiver.finish(with: .failure(CancellationError()))
            }
        }
        try? await stream.stopCapture()
        return image
    }
}

// CoreAudio Process Tap SDK constants and stub types (macOS 14.2+)
let kAudioHardwarePropertyProcessObjectList: AudioObjectPropertySelector = 0x70727323 // 'prs#'
let kAudioHardwarePropertyTranslatePIDToProcessObject: AudioObjectPropertySelector = 0x69643270 // 'id2p'
let kAudioProcessPropertyPID: AudioObjectPropertySelector = 0x70706964 // 'ppid'
let kAudioProcessPropertyBundleID: AudioObjectPropertySelector = 0x70626964 // 'pbid'
let kAudioProcessPropertyDevices: AudioObjectPropertySelector = 0x70647623 // 'pdv#'
let kAudioProcessPropertyIsRunning: AudioObjectPropertySelector = 0x7069723F // 'pir?'
let kAudioProcessPropertyIsRunningOutput: AudioObjectPropertySelector = 0x7069726F // 'piro'
let kAudioTapPropertyFormat: AudioObjectPropertySelector = 0x74666D74 // 'tfmt'

let kAudioAggregateDeviceTapListKey: String = "taps"
let kAudioSubTapUIDKey: String = "uid"
let kAudioSubTapDriftCompensationKey: String = "drift"
let kAudioAggregateDeviceTapAutoStartKey: String = "tapautostart"

enum CATapMuteBehavior: Int {
    case unmuted = 0
    case muted = 1
    case mutedWhenTapped = 2
}

final class CATapDescription: NSObject {
    var name: String?
    var uuid = UUID()
    var isPrivate: Bool = true
    var muteBehavior: CATapMuteBehavior = .unmuted

    init(stereoMixdownOfProcesses processes: [AudioObjectID]) {
        super.init()
    }

    init(stereoGlobalTapButExcludeProcesses processes: [AudioObjectID]) {
        super.init()
    }
}

func AudioHardwareCreateProcessTap(_ description: CATapDescription,
                                   _ outTapID: UnsafeMutablePointer<AudioObjectID>?) -> OSStatus {
    outTapID?.pointee = 0
    return OSStatus(kAudioHardwareUnsupportedOperationError)
}

@discardableResult
func AudioHardwareDestroyProcessTap(_ tapID: AudioObjectID) -> OSStatus {
    OSStatus(kAudioHardwareUnsupportedOperationError)
}

// MARK: - CADisplayLink Compatibility Shim (macOS 12 / 13)

final class CADisplayLink: NSObject {
    private var targetObject: AnyObject?
    private let selector: Selector
    private var timer: Timer?
    private var addedRunLoop: RunLoop?
    private var addedMode: RunLoop.Mode?

    var preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60) {
        didSet {
            if timer != nil {
                rescheduleTimer()
            }
        }
    }

    var isPaused: Bool = false
    private(set) var timestamp: CFTimeInterval = CACurrentMediaTime()
    private(set) var duration: CFTimeInterval = 1.0 / 60.0
    var targetTimestamp: CFTimeInterval { timestamp + duration }

    init(target: Any, selector: Selector) {
        self.targetObject = target as AnyObject
        self.selector = selector
        super.init()
    }

    func add(to runloop: RunLoop, forMode mode: RunLoop.Mode) {
        addedRunLoop = runloop
        addedMode = mode
        rescheduleTimer()
    }

    private func rescheduleTimer() {
        timer?.invalidate()
        guard let runloop = addedRunLoop, let mode = addedMode else { return }
        let preferred = preferredFrameRateRange.preferred ?? 60.0
        let fps = preferred > 0 ? Double(preferred) : 60.0
        let interval = max(1.0 / 240.0, 1.0 / fps)
        duration = interval
        timestamp = CACurrentMediaTime()
        let newTimer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            guard let self, !self.isPaused, let target = self.targetObject else { return }
            self.timestamp = CACurrentMediaTime()
            _ = target.perform(self.selector, with: self)
        }
        newTimer.tolerance = interval * 0.1
        runloop.add(newTimer, forMode: mode)
        timer = newTimer
    }

    func invalidate() {
        timer?.invalidate()
        timer = nil
        addedRunLoop = nil
        addedMode = nil
        targetObject = nil
    }
}

extension NSScreen {
    func displayLink(target: Any, selector: Selector) -> CADisplayLink {
        CADisplayLink(target: target, selector: selector)
    }
}

extension NSView {
    func displayLink(target: Any, selector: Selector) -> CADisplayLink {
        CADisplayLink(target: target, selector: selector)
    }
}

extension AVAssetImageGenerator {
    public func image(at time: CMTime) async throws -> (image: CGImage, actualTime: CMTime) {
        var actualTime = CMTime.zero
        let cgImage = try self.copyCGImage(at: time, actualTime: &actualTime)
        return (image: cgImage, actualTime: actualTime)
    }
}

extension AVCaptureSession {
    public static var runtimeErrorNotification: NSNotification.Name {
        .AVCaptureSessionRuntimeError
    }
    public static var wasInterruptedNotification: NSNotification.Name {
        .AVCaptureSessionWasInterrupted
    }
}

extension AVCaptureDevice.DeviceType {
    public static let external = AVCaptureDevice.DeviceType.externalUnknown
    public static let continuityCamera = AVCaptureDevice.DeviceType(rawValue: "AVCaptureDeviceTypeContinuityCamera")
}

#endif

// MARK: - Duration & ContinuousClock Compatibility Shim (macOS 12+)

struct Duration: Comparable, Equatable, Hashable, Sendable {
    let components: (seconds: Int64, attoseconds: Int64)

    static let zero = Duration(components: (0, 0))

    init(secondsComponent: Int64, attosecondsComponent: Int64) {
        let extraSeconds = attosecondsComponent / 1_000_000_000_000_000_000
        let remAtto = attosecondsComponent % 1_000_000_000_000_000_000
        self.components = (secondsComponent + extraSeconds, remAtto)
    }

    init(components: (seconds: Int64, attoseconds: Int64)) {
        self.init(secondsComponent: components.seconds, attosecondsComponent: components.attoseconds)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(components.seconds)
        hasher.combine(components.attoseconds)
    }

    var timeInterval: Double {
        Double(components.seconds) + Double(components.attoseconds) / 1e18
    }

    static func seconds(_ value: Double) -> Duration {
        guard value.isFinite else { return .zero }
        let whole = Int64(value.rounded(.towardZero))
        let frac = value - Double(whole)
        let atto = Int64((frac * 1e18).rounded())
        return Duration(secondsComponent: whole, attosecondsComponent: atto)
    }

    static func seconds<T: BinaryInteger>(_ value: T) -> Duration {
        Duration(secondsComponent: Int64(value), attosecondsComponent: 0)
    }

    static func milliseconds<T: BinaryInteger>(_ value: T) -> Duration {
        let ms = Int64(value)
        let secs = ms / 1_000
        let remMs = ms % 1_000
        return Duration(secondsComponent: secs, attosecondsComponent: remMs * 1_000_000_000_000_000)
    }

    static func milliseconds(_ value: Double) -> Duration {
        .seconds(value / 1_000.0)
    }

    static func < (lhs: Duration, rhs: Duration) -> Bool {
        if lhs.components.seconds != rhs.components.seconds {
            return lhs.components.seconds < rhs.components.seconds
        }
        return lhs.components.attoseconds < rhs.components.attoseconds
    }

    static func == (lhs: Duration, rhs: Duration) -> Bool {
        lhs.components.seconds == rhs.components.seconds
            && lhs.components.attoseconds == rhs.components.attoseconds
    }

    static func + (lhs: Duration, rhs: Duration) -> Duration {
        Duration(secondsComponent: lhs.components.seconds + rhs.components.seconds,
                 attosecondsComponent: lhs.components.attoseconds + rhs.components.attoseconds)
    }

    static func - (lhs: Duration, rhs: Duration) -> Duration {
        Duration(secondsComponent: lhs.components.seconds - rhs.components.seconds,
                 attosecondsComponent: lhs.components.attoseconds - rhs.components.attoseconds)
    }

    struct UnitsFormatStyle: Sendable {
        enum Unit: Hashable, Sendable {
            case hours
            case minutes
            case seconds
        }

        enum UnitWidth: Sendable {
            case wide
            case abbreviated
            case narrow
        }

        enum ZeroValueUnitsDisplayStrategy: Sendable {
            case hide
            case show(length: Int)
        }

        struct FractionalPartDisplayStrategy: Sendable {
            static func hide(rounded: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> Self {
                Self()
            }
        }

        var allowedUnits: Set<Unit>
        var width: UnitWidth
        var locale: Locale = .current

        func locale(_ newLocale: Locale) -> UnitsFormatStyle {
            var copy = self
            copy.locale = newLocale
            return copy
        }
    }

    func formatted(_ style: UnitsFormatStyle) -> String {
        if #available(macOS 13.0, *) {
            let stdDuration = Swift.Duration(secondsComponent: components.seconds,
                                             attosecondsComponent: components.attoseconds)
            var stdUnits = Set<Swift.Duration.UnitsFormatStyle.Unit>()
            if style.allowedUnits.contains(.hours) { stdUnits.insert(.hours) }
            if style.allowedUnits.contains(.minutes) { stdUnits.insert(.minutes) }
            if style.allowedUnits.contains(.seconds) { stdUnits.insert(.seconds) }
            let stdWidth: Swift.Duration.UnitsFormatStyle.UnitWidth
            switch style.width {
            case .wide: stdWidth = .wide
            case .abbreviated: stdWidth = .abbreviated
            case .narrow: stdWidth = .narrow
            }
            return stdDuration.formatted(
                Swift.Duration.UnitsFormatStyle(
                    allowedUnits: stdUnits,
                    width: stdWidth,
                    fractionalPart: .hide(rounded: .down)
                ).locale(style.locale)
            )
        }

        let totalSeconds = max(0, Int(floor(timeInterval + 1e-9)))
        let formatter = DateComponentsFormatter()
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = style.locale
        formatter.calendar = calendar
        var units: NSCalendar.Unit = []
        if style.allowedUnits.contains(.hours) { units.insert(.hour) }
        if style.allowedUnits.contains(.minutes) { units.insert(.minute) }
        if style.allowedUnits.contains(.seconds) { units.insert(.second) }
        formatter.allowedUnits = units
        switch style.width {
        case .wide:
            formatter.unitsStyle = .full
            formatter.zeroFormattingBehavior = .dropAll
        case .abbreviated, .narrow:
            formatter.unitsStyle = .abbreviated
            formatter.zeroFormattingBehavior = .dropAll
        }
        var dc = DateComponents()
        var remaining = totalSeconds
        if style.allowedUnits.contains(.hours) {
            dc.hour = remaining / 3600
            remaining %= 3600
        }
        if style.allowedUnits.contains(.minutes) {
            dc.minute = remaining / 60
            remaining %= 60
        }
        if style.allowedUnits.contains(.seconds) {
            dc.second = remaining
        }
        if let formatted = formatter.string(from: dc), !formatted.isEmpty {
            return formatted
        }
        return "\(totalSeconds)s"
    }
}

extension Duration.UnitsFormatStyle {
    static func units(
        allowed: Set<Unit>,
        width: UnitWidth,
        maximumUnitCount: Int? = nil,
        zeroValueUnits: ZeroValueUnitsDisplayStrategy = .hide,
        valueLength: Int? = nil,
        fractionalPart: FractionalPartDisplayStrategy = .hide()
    ) -> Duration.UnitsFormatStyle {
        Duration.UnitsFormatStyle(allowedUnits: allowed, width: width)
    }
}

struct ContinuousClock: Sendable {
    struct Instant: Comparable, Equatable, Hashable, Sendable {
        let uptime: TimeInterval

        static var now: Instant {
            Instant(uptime: ProcessInfo.processInfo.systemUptime)
        }

        func advanced(by duration: Duration) -> Instant {
            Instant(uptime: uptime + duration.timeInterval)
        }

        func duration(to other: Instant) -> Duration {
            .seconds(other.uptime - uptime)
        }

        static func < (lhs: Instant, rhs: Instant) -> Bool {
            lhs.uptime < rhs.uptime
        }

        static func + (lhs: Instant, rhs: Duration) -> Instant {
            lhs.advanced(by: rhs)
        }
    }

    static var now: Instant { .now }
}

enum VorssaintClockKind: Sendable {
    case continuous
}

extension Task where Success == Never, Failure == Never {
    static func sleep(for duration: Duration,
                      clock: VorssaintClockKind = .continuous) async throws {
        let seconds = max(0, duration.timeInterval)
        let nanoseconds = UInt64((seconds * 1_000_000_000).rounded())
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}

extension URL {
    func appending(path: String) -> URL {
        appendingPathComponent(path)
    }
}

extension Data {
    func contains(_ other: Data) -> Bool {
        range(of: other) != nil
    }
}

extension MainActor {
    static func assumeIsolated<T>(_ operation: @MainActor () throws -> T, file: StaticString = #fileID, line: UInt = #line) rethrows -> T {
        typealias NonIsolatedFn = () throws -> T
        return try withoutActuallyEscaping(operation) { fn in
            let raw = unsafeBitCast(fn, to: NonIsolatedFn.self)
            return try raw()
        }
    }
}

extension UnsafeMutablePointer {
    func update(from source: UnsafePointer<Pointee>, count: Int) {
        initialize(from: source, count: count)
    }
    func update(repeating repeatedValue: Pointee, count: Int) {
        initialize(repeating: repeatedValue, count: count)
    }
}

extension NSImage {
    private static let _swizzleOnce: Void = {
        guard let originalMethod = class_getClassMethod(NSImage.self, #selector(NSImage.init(systemSymbolName:accessibilityDescription:))),
              let swizzledMethod = class_getClassMethod(NSImage.self, #selector(NSImage.compat_imageWithSystemSymbolName(_:accessibilityDescription:)))
        else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()

    @objc dynamic class func compat_imageWithSystemSymbolName(_ name: String, accessibilityDescription: String?) -> NSImage? {
        if let img = self.compat_imageWithSystemSymbolName(name, accessibilityDescription: accessibilityDescription) {
            return img
        }
        let symbolFallbacks: [String: String] = [
            "mountain.2.fill": "cloud.fill",
            "gauge.with.dots.needle.67percent": "speedometer",
            "cat.fill": "hare.fill",
            "bubble.left.and.text.bubble.right": "bubble.left.and.bubble.right",
            "bubble.left.and.text.bubble.right.fill": "bubble.left.and.bubble.right.fill",
            "calendar.badge.checkmark": "calendar",
            "network.slash": "network",
            "photo.badge.plus": "photo",
            "web.camera": "camera",
            "av.remote": "tv",
        ]
        if let fallback = symbolFallbacks[name] {
            return self.compat_imageWithSystemSymbolName(fallback, accessibilityDescription: accessibilityDescription)
        }
        return nil
    }

    public static func installSymbolCompatibility() {
        _ = _swizzleOnce
    }
}
