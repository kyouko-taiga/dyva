/// Marks this execution path as unreachable, causing a fatal error otherwise.
public func unreachable(
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line
) -> Never {
  fatalError(message(), file: file, line: line)
}
