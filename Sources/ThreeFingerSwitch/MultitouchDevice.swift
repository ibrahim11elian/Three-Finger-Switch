import Darwin
import Foundation

// Kept local because the private framework does not ship a public Swift header.
private struct MTPoint {
  var x: Float
  var y: Float
}

private struct MTVector {
  var position: MTPoint
  var velocity: MTPoint
}

private struct MTContact {
  var frame: Int32
  var timestamp: Double
  var identifier: Int32
  var state: Int32
  var fingerID: Int32
  var handID: Int32
  var normalized: MTVector
  var size: Float
  var unknown1: Int32
  var angle: Float
  var majorAxis: Float
  var minorAxis: Float
  var absolute: MTVector
  var unknown2: Int32
  var unknown3: Int32
  var density: Float
}

private typealias MTDeviceRef = UnsafeMutableRawPointer
private typealias ContactCallback =
  @convention(c) (
    MTDeviceRef?,
    UnsafeMutableRawPointer?,
    Int32,
    Double,
    Int32
  ) -> Void
private typealias CreateDefaultFunction = @convention(c) () -> MTDeviceRef?
private typealias RegisterCallbackFunction = @convention(c) (MTDeviceRef?, ContactCallback?) -> Void
private typealias UnregisterCallbackFunction =
  @convention(c) (MTDeviceRef?, ContactCallback?) -> Void
private typealias StartFunction = @convention(c) (MTDeviceRef?, Int32) -> Int32
private typealias StopFunction = @convention(c) (MTDeviceRef?) -> Int32
private typealias ReleaseFunction = @convention(c) (MTDeviceRef?) -> Void

private struct MultitouchSymbols {
  let createDefault: CreateDefaultFunction
  let register: RegisterCallbackFunction
  let unregister: UnregisterCallbackFunction
  let start: StartFunction
  let stop: StopFunction
  let release: ReleaseFunction
}

private let contactCallback: ContactCallback = { _, contacts, count, timestamp, _ in
  MultitouchDevice.shared.receive(contacts: contacts, count: Int(count), timestamp: timestamp)
}

final class MultitouchDevice {
  static let shared = MultitouchDevice()

  enum DeviceError: LocalizedError, Equatable {
    case frameworkUnavailable
    case symbolsUnavailable
    case trackpadUnavailable
    case startFailed
    case invalidContactData

    var errorDescription: String? {
      switch self {
      case .frameworkUnavailable:
        return "Apple's MultitouchSupport framework is unavailable."
      case .symbolsUnavailable:
        return "This macOS version has incompatible multitouch APIs."
      case .trackpadUnavailable:
        return "No trackpad was found."
      case .startFailed:
        return "The trackpad could not be started."
      case .invalidContactData:
        return "This macOS version returned incompatible trackpad data."
      }
    }
  }

  var onFrame: ((Int, SIMD2<Float>?, TimeInterval) -> Void)?
  var onError: ((DeviceError) -> Void)?

  private var framework: UnsafeMutableRawPointer?
  private var symbols: MultitouchSymbols?
  private var device: MTDeviceRef?
  private var reportedInvalidContactData = false

  private init() {}

  deinit {
    stop()
  }

  func start() throws {
    guard device == nil else { return }
    guard MemoryLayout<MTContact>.size == 96 else { throw DeviceError.invalidContactData }
    let symbols = try resolvedSymbols()
    device = try startDefaultDevice(using: symbols)
    reportedInvalidContactData = false
  }

  func stop() {
    guard let device, let symbols else { return }
    symbols.unregister(device, contactCallback)
    _ = symbols.stop(device)
    symbols.release(device)
    self.device = nil
  }

  // The framework stays loaded because a callback may already be in flight during shutdown.
  private func resolvedSymbols() throws -> MultitouchSymbols {
    if let symbols { return symbols }
    let framework = try openFramework()
    do {
      let symbols = try loadSymbols(from: framework)
      self.framework = framework
      self.symbols = symbols
      return symbols
    } catch {
      dlclose(framework)
      throw error
    }
  }

  private func openFramework() throws -> UnsafeMutableRawPointer {
    let path = "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport"
    guard let framework = dlopen(path, RTLD_NOW | RTLD_LOCAL) else {
      throw DeviceError.frameworkUnavailable
    }
    return framework
  }

  private func loadSymbols(from framework: UnsafeMutableRawPointer) throws -> MultitouchSymbols {
    guard
      let createDefault = loadSymbol(
        "MTDeviceCreateDefault", from: framework, as: CreateDefaultFunction.self),
      let register = loadSymbol(
        "MTRegisterContactFrameCallback", from: framework, as: RegisterCallbackFunction.self),
      let unregister = loadSymbol(
        "MTUnregisterContactFrameCallback", from: framework, as: UnregisterCallbackFunction.self),
      let start = loadSymbol("MTDeviceStart", from: framework, as: StartFunction.self),
      let stop = loadSymbol("MTDeviceStop", from: framework, as: StopFunction.self),
      let release = loadSymbol("MTDeviceRelease", from: framework, as: ReleaseFunction.self)
    else {
      throw DeviceError.symbolsUnavailable
    }
    return MultitouchSymbols(
      createDefault: createDefault,
      register: register,
      unregister: unregister,
      start: start,
      stop: stop,
      release: release
    )
  }

  private func loadSymbol<T>(
    _ name: String,
    from framework: UnsafeMutableRawPointer,
    as type: T.Type
  ) -> T? {
    guard let symbol = dlsym(framework, name) else { return nil }
    return unsafeBitCast(symbol, to: type)
  }

  private func startDefaultDevice(using symbols: MultitouchSymbols) throws -> MTDeviceRef {
    guard let device = symbols.createDefault() else {
      throw DeviceError.trackpadUnavailable
    }
    symbols.register(device, contactCallback)
    guard symbols.start(device, 0) == 0 else {
      symbols.unregister(device, contactCallback)
      symbols.release(device)
      throw DeviceError.startFailed
    }
    return device
  }

  fileprivate func receive(
    contacts: UnsafeMutableRawPointer?,
    count: Int,
    timestamp: TimeInterval
  ) {
    guard timestamp.isFinite, count >= 0, count <= 20 else {
      reportInvalidContactData()
      return
    }
    if count == 0 {
      onFrame?(0, nil, timestamp)
      return
    }
    guard let contacts else {
      reportInvalidContactData()
      return
    }

    let typedContacts = contacts.assumingMemoryBound(to: MTContact.self)
    var sum = SIMD2<Float>.zero
    for index in 0..<count {
      let point = typedContacts[index].normalized.position
      guard point.x.isFinite, point.y.isFinite,
        (-0.1...1.1).contains(point.x), (-0.1...1.1).contains(point.y)
      else {
        reportInvalidContactData()
        return
      }
      sum += SIMD2(point.x, point.y)
    }
    onFrame?(count, sum / Float(count), timestamp)
  }

  private func reportInvalidContactData() {
    guard !reportedInvalidContactData else { return }
    reportedInvalidContactData = true
    onError?(.invalidContactData)
  }
}
