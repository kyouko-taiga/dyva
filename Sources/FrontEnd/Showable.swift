/// A type whose instance have a textual representation.
public protocol Showable {

  /// Returns a textual representation of `self`, which is in `module`.
  func show(using module: Module) -> String

}
