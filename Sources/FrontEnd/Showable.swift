/// A type whose instance have a textual representation.
public protocol Showable {

  /// Returns a textual representation of `self` using `program`.
  func show(using program: Program) -> String

}
