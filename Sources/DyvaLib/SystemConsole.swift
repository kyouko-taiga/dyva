import Dispatch
import Foundation

/// The standard input, output, and error streams of the process.
public struct SystemConsole: Console {

  /// The type of the console's output stream.
  public typealias Output = SystemOutputStream

  /// The type of the console's error output stream.
  public typealias Error = SystemOutputStream

  /// The standard input.
  private var input: SynchronizedFileHandle = .init(FileHandle.standardInput)

  /// The standard output.
  public var output: SystemOutputStream = .out()

  /// The standard error.
  public var error: SystemOutputStream = .error()

  /// Creates a new instance.
  public init() {}

  public mutating func read(upTo count: Int, into buffer: UnsafeMutablePointer<UInt8>) -> Int {
    input.read(upTo: count, into: buffer)
  }

}

/// A wrapper around a handle to a standard output stream.
public struct SystemOutputStream {

  /// The wrapped handle.
  private var handle: SynchronizedFileHandle

  /// Creates an instance wrapping the given handle.
  private init(_ handle: FileHandle) {
    self.handle = .init(handle)
  }

  /// The standard output.
  public static func out() -> Self {
    .init(FileHandle.standardOutput)
  }

  /// The standard error.
  public static func error() -> Self {
    .init(FileHandle.standardError)
  }

}

extension SystemOutputStream: TextOutputStream {

  public mutating func write(_ string: String) {
    handle.write(string)
  }

}

/// A wrapper for synchronizing access to a file handle.
private struct SynchronizedFileHandle {

  /// The wrapped handle.
  private let handle: FileHandle

  /// The synchronization mechanism that makes `self` threadsafe.
  private let mutex: DispatchQueue

  /// Creates an instance wrapping `handle`.
  fileprivate init(_ handle: FileHandle) {
    self.handle = handle
    self.mutex = DispatchQueue(label: "org.dyva-lang.\(ObjectIdentifier(handle))")
  }

  /// Writes `string` to the stream.
  fileprivate mutating func write(_ string: String) {
    if string.isEmpty { return }
    mutex.sync {
      var s = string
      s.withUTF8({ (utf8) in try! handle.write(contentsOf: utf8) })
    }
  }

  /// Reads up to `count` bytes from the stream, writes them to `buffer` and returns the number of
  /// bytes written.
  ///
  /// - Requires: `buffer` points to a buffer large enough to store `count` elements.
  fileprivate func read(upTo count: Int, into buffer: UnsafeMutablePointer<UInt8>) -> Int {
    if count == 0 { return 0 }

    var data: Data?
    mutex.sync {
      data = try? handle.read(upToCount: count)
    }

    if let d = data {
      d.copyBytes(to: .init(buffer), count: d.count)
      return d.count
    } else {
      return 0
    }
  }

}
