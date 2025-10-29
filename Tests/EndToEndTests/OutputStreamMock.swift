/// A mock of a standard output stream used during testing.
struct OutputStreamMock: TextOutputStream {

  /// The kind of a stream.
  enum Kind: String {

    /// The standard output.
    case stdout

    /// The standard error.
    case stderr

  }

  /// The kind of this steam.
  let kind: Kind

  /// The contents of the stream.
  private(set) var contents: String = ""

  /// Appends the given string to this stream.
  mutating func write(_ string: String) {
    contents.write(string)
  }

}
