import DyvaLib

/// A mock of a console used during testing.
struct ConsoleMock {

  /// The contents of the input stream.
  let input: String

  /// The current position in the input stream.
  private var inputPosition: String.UTF8View.Index

  /// The output stream.
  var output: OutputStreamMock

  /// The error output stream.
  var error: OutputStreamMock

  /// Creates an instance with empty streams.
  init() {
    self.input = .init()
    self.inputPosition = self.input.utf8.startIndex

    self.output = .init(kind: .stdout)
    self.error = .init(kind: .stderr)
  }

}

extension ConsoleMock: Console {

  typealias Output = OutputStreamMock

  typealias Error = OutputStreamMock

  mutating func read(upTo count: Int, into buffer: UnsafeMutablePointer<UInt8>) -> Int {
    let source = input.utf8
    var n = 0
    while (n < count) && (inputPosition != source.endIndex) {
      buffer[n] = source[inputPosition]
      n += 1
      inputPosition = source.index(after: inputPosition)
    }
    return n
  }

}
