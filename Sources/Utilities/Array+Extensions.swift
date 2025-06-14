extension Array {

  /// Creates an array capable of storing `minimumCapacity` elements before allocating new storage.
  public init(minimumCapacity: Int) {
    self.init()
    self.reserveCapacity(minimumCapacity)
  }

}
