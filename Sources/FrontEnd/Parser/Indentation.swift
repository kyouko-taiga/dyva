/// A description of how text is indented.
internal struct Indentation {

  /// The symbol being used for indentation.
  internal let symbol: Character

  /// The number of times `symbol` has been repeated.
  internal var level: Int

}
