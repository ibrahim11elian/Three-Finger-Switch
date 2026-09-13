public enum CarouselIndex {
  public static func destination(
    from currentIndex: Int,
    count: Int,
    direction: SwipeDirection
  ) -> Int? {
    guard count > 1, (0..<count).contains(currentIndex) else { return nil }
    let offset = direction == .right ? 1 : -1
    return (currentIndex + offset + count) % count
  }
}
