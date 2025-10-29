import Testing
import Utilities

struct ArrayTests {

  @Test func initWithMinimumCapacity() {
    let a = [Int](minimumCapacity: 100)
    #expect(a.capacity >= 100)
  }

}
