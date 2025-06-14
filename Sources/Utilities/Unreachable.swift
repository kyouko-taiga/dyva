/// Marks this execution path as unreachable, causing a fatal error otherwise.
public func unreachable(
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line
) -> Never {
  fatalError(message(), file: file, line: line)
}

/// Marks that this execution path is not done yet.
public func todo(
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line
) -> Never {
  fatalError(message(), file: file, line: line)
}
