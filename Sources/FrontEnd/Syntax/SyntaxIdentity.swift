/// A type denoting the identity of a node in an abstract syntax tree.
public protocol SyntaxIdentity: Hashable, Showable, Sendable {

  /// The type-erased value of this identity.
  var widened: AnySyntaxIdentity { get }

  /// Creates an identifying the same node as `widened`.
  init(uncheckedFrom widened: AnySyntaxIdentity)

}

extension SyntaxIdentity {

  /// The identity of the module containing the node represented by `self`.
  public var module: Module.Identity {
    widened.module
  }

  /// The offset of the node represented by `self` in its containing collection.
  public var offset: Int {
    widened.offset
  }

  /// Returns `true` iff `l` denotes the same node as `r`.
  public static func == <T: SyntaxIdentity>(l: Self, r: T) -> Bool {
    l.widened == r.widened
  }

  /// Returns `true` iff `l` denotes the same node as `r`.
  public static func ~= <T: SyntaxIdentity>(l: Self, r: T) -> Bool {
    l.widened == r.widened
  }

  /// Returns a textual representation of `self`, which is in `module`.
  public func show(using module: Module) -> String {
    module[self].show(using: module)
  }

}

/// The type-erased identity of an abstract syntax tree.
///
/// An identity is composed of two offsets:
/// - `module`: an offset identifying the module in which the node is contained.
/// - `node`: an offset identifying the node itself.
///
/// Both offsets are interpreted as unsigned integers. The maximum representable value of the node
/// offset is reserved as a tag.
public struct AnySyntaxIdentity {

  /// The bit representation of `self`.
  public let bits: UInt64

  /// Creates an instance with the given bit representation.
  public init(bits: UInt64) {
    self.bits = bits
  }

  /// Creates an instance identifying the node at offset `n` in module `m`.
  public init(module m: Module.Identity, offset n: Int) {
    precondition(n < UInt32.max)
    self.bits = (UInt64(m) << 32) | UInt64(n)
  }

  /// Creates an identifying the same node as `other`.
  public init<T: SyntaxIdentity>(_ other: T) {
    self.bits = other.widened.bits
  }

  /// The identity of the module containing the node represented by `self`.
  public var module: Module.Identity {
    UInt32(bits >> 32)
  }

  /// The offset of the node represented by `self` in its containing collection.
  public var offset: Int {
    .init(bits & 0xffffffff)
  }

}

extension AnySyntaxIdentity: SyntaxIdentity {

  /// Creates an identifying the same node as `widened`.
  public init(uncheckedFrom widened: AnySyntaxIdentity) {
    self = widened
  }

  /// The type-erased value of this identity.
  public var widened: AnySyntaxIdentity {
    self
  }

  /// Returns `true` iff `l` denotes the same node as `r`.
  public static func == <T: SyntaxIdentity>(l: Self, r: T) -> Bool {
    l.bits == r.widened.bits
  }

  /// Returns `true` if `l` is ordered before `r`.
  public static func < (l: Self, r: Self) -> Bool {
    l.bits < r.bits
  }

}

extension AnySyntaxIdentity: CustomStringConvertible {

  public var description: String {
    bits.description
  }

}

/// The identity of a node in an abstract syntax tree.
public struct ConcreteSyntaxIdentity<T: Syntax>: SyntaxIdentity {

  /// The type-erased value of this identity.
  public let widened: AnySyntaxIdentity

  /// Creates an identifying the same node as `widened`.
  public init(uncheckedFrom widened: AnySyntaxIdentity) {
    self.widened = widened
  }

}

/// The type-erased identity of an abstract syntax tree denoting a declaration.
public struct DeclarationIdentity: SyntaxIdentity {

  /// The type-erased value of this identity.
  public let widened: AnySyntaxIdentity

  /// Creates an identifying the same node as `widened`.
  public init(uncheckedFrom widened: AnySyntaxIdentity) {
    self.widened = widened
  }

  /// Creates an instance equal to `other`.
  public init<T: Declaration>(_ other: T.ID) {
    self.widened = other.widened
  }

}

/// The type-erased identitiy of an abstract syntax tree denoting an expression.
public struct ExpressionIdentity: SyntaxIdentity {

  /// The type-erased value of this identity.
  public let widened: AnySyntaxIdentity

  /// Creates an identifying the same node as `widened`.
  public init(uncheckedFrom widened: AnySyntaxIdentity) {
    self.widened = widened
  }

  /// Creates an instance equal to `other`.
  public init<T: Expression>(_ other: T.ID) {
    self.widened = other.widened
  }

}

/// The type-erased identity of an abstract syntax tree denoting a pattern.
public struct PatternIdentity: SyntaxIdentity {

  /// The type-erased value of this identity.
  public let widened: AnySyntaxIdentity

  /// Creates an identifying the same node as `widened`.
  public init(uncheckedFrom widened: AnySyntaxIdentity) {
    self.widened = widened
  }

  /// Creates an instance equal to `other`.
  public init<T: Pattern>(_ other: T.ID) {
    self.widened = other.widened
  }

  /// Creates an instance equal to `other`.
  public init(_ other: ExpressionIdentity) {
    self.widened = other.widened
  }

}

/// The type-erased identity of an abstract syntax tree denoting a statement.
public struct StatementIdentity: SyntaxIdentity {

  /// The type-erased value of this identity.
  public let widened: AnySyntaxIdentity

  /// Creates an identifying the same node as `widened`.
  public init(uncheckedFrom widened: AnySyntaxIdentity) {
    self.widened = widened
  }

  /// Creates an instance equal to `other`.
  public init<T: Statement>(_ other: T.ID) {
    self.widened = other.widened
  }

  /// Creates an instance equal to `other`.
  public init(_ other: DeclarationIdentity) {
    self.widened = other.widened
  }

  /// Creates an instance equal to `other`.
  public init(_ other: ExpressionIdentity) {
    self.widened = other.widened
  }

}

/// The identity of an expression or binding declaration in the conditions of an if-expression,
/// match-expression, or while loop.
public struct ConditionIdentity: SyntaxIdentity {

  /// The type-erased value of this identity.
  public let widened: AnySyntaxIdentity

  /// Creates an identifying the same node as `widened`.
  public init(uncheckedFrom widened: AnySyntaxIdentity) {
    self.widened = widened
  }

  /// Creates an instance equal to `other`.
  public init(_ other: ExpressionIdentity) {
    self.widened = other.widened
  }

  /// Creates an instance equal to `other`.
  public init(_ other: MatchCondition.ID) {
    self.widened = other.widened
  }

}

/// The identity of the else-branch of a conditional expression.
public struct ElseIdentity: SyntaxIdentity {

  /// The type-erased value of this identity.
  public let widened: AnySyntaxIdentity

  /// Creates an identifying the same node as `widened`.
  public init(uncheckedFrom widened: AnySyntaxIdentity) {
    self.widened = widened
  }

  /// Creates an instance equal to `other`.
  public init(_ other: ConditionalExpression.ID) {
    self.widened = other.widened
  }

  /// Creates an instance equal to `other`.
  public init(_ other: Block.ID) {
    self.widened = other.widened
  }

}
