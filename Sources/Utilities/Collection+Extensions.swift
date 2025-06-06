extension Collection {

  /// The unique element of `self` if `self` contains exactly one element; otherwise, `nil`.
  public var uniqueElement: Element? {
    count == 1 ? self[startIndex] : nil
  }

  /// The first element of `self` and its suffix after its first index or `nil` if `self` is empty.
  public var headAndTail: (head: Element, tail: SubSequence)? {
    if isEmpty { return nil }
    return (head: self[startIndex], tail: self[index(after: startIndex)...])
  }

}

extension RangeReplaceableCollection where Element: Hashable {

  /// Removes all except the first element from every consecutive group of equivalent elements.
  ///
  /// - Complexity: O(n) where n is the length of `self`.
  public mutating func removeDuplicates() {
    var s = Set<Element>(minimumCapacity: count)
    var i = startIndex
    while i != endIndex {
      if s.insert(self[i]).inserted {
        formIndex(after: &i)
      } else {
        remove(at: i)
      }
    }
  }

}
