/// A type that implements the interface of a character-based console.
public protocol Console {

  /// The type of the console's output stream.
  associatedtype Output: TextOutputStream

  /// The type of the console's error output stream.
  associatedtype Error: TextOutputStream

  /// The console's output stream.
  var output: Output { get set }

  /// The console's error output stream.
  var error: Error { get set }

  /// Reads up to `count` bytes from the stream, writes them to `buffer` and returns the number of
  /// bytes written.
  ///
  /// - Requires: `buffer` points to a buffer large enough to store `count` elements.
  mutating func read(upTo count: Int, into buffer: UnsafeMutablePointer<UInt8>) -> Int

}
