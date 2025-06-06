/// A character boundary in a source file.
public struct SourcePosition: Hashable {

  /// The source file containing the position.
  public let source: SourceFile

  /// The position relative to the source file.
  public let index: String.Index

  /// Creates an instance with the given properties.
  public init(_ index: String.Index, in file: SourceFile) {
    self.source = file
    self.index = index
  }

  /// The line and column number of this position.
  public var lineAndColumn: (line: Int, column: Int) {
    let r = source.lineAndColumn(index)
    return (r.line, r.column)
  }

}

extension SourcePosition: Comparable {

  public static func < (l: Self, r: Self) -> Bool {
    precondition(l.source == r.source, "incompatible locations")
    return l.index < r.index
  }

}

extension SourcePosition: CustomStringConvertible {

  public var description: String {
    let (line, column) = lineAndColumn
    return "\(source.name):\(line):\(column)"
  }

}
