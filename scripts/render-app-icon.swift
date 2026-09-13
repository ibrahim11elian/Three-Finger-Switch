import AppKit

private let canvasSize = NSSize(width: 1024, height: 1024)
private let image = NSImage(size: canvasSize)

image.lockFocus()
guard let context = NSGraphicsContext.current else {
  fatalError("Could not create an icon drawing context")
}
context.imageInterpolation = .high

NSColor.clear.setFill()
NSRect(origin: .zero, size: canvasSize).fill()

let tileRect = NSRect(x: 76, y: 76, width: 872, height: 872)
let tile = NSBezierPath(roundedRect: tileRect, xRadius: 205, yRadius: 205)

NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.24)
shadow.shadowBlurRadius = 34
shadow.shadowOffset = NSSize(width: 0, height: -18)
shadow.set()
NSColor(calibratedRed: 0.20, green: 0.34, blue: 0.84, alpha: 1).setFill()
tile.fill()
NSGraphicsContext.restoreGraphicsState()

let highlight = NSBezierPath(roundedRect: tileRect.insetBy(dx: 1, dy: 1), xRadius: 204, yRadius: 204)
NSColor.white.withAlphaComponent(0.16).setStroke()
highlight.lineWidth = 2
highlight.stroke()

let markColor = NSColor(calibratedWhite: 0.98, alpha: 1)
markColor.setFill()
markColor.setStroke()

func fillCapsule(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
  NSBezierPath(
    roundedRect: NSRect(x: x, y: y, width: width, height: height),
    xRadius: width / 2,
    yRadius: width / 2
  ).fill()
}

fillCapsule(x: 326, y: 474, width: 92, height: 234)
fillCapsule(x: 466, y: 474, width: 92, height: 302)
fillCapsule(x: 606, y: 474, width: 92, height: 234)

let rail = NSBezierPath()
rail.lineWidth = 42
rail.lineCapStyle = .round
rail.lineJoinStyle = .round
rail.move(to: NSPoint(x: 284, y: 344))
rail.line(to: NSPoint(x: 740, y: 344))
rail.stroke()

let arrowSize: CGFloat = 74
let leftArrow = NSBezierPath()
leftArrow.move(to: NSPoint(x: 284, y: 344))
leftArrow.line(to: NSPoint(x: 284 + arrowSize, y: 344 + arrowSize))
leftArrow.line(to: NSPoint(x: 284 + arrowSize, y: 344 - arrowSize))
leftArrow.close()
leftArrow.fill()

let rightArrow = NSBezierPath()
rightArrow.move(to: NSPoint(x: 740, y: 344))
rightArrow.line(to: NSPoint(x: 740 - arrowSize, y: 344 + arrowSize))
rightArrow.line(to: NSPoint(x: 740 - arrowSize, y: 344 - arrowSize))
rightArrow.close()
rightArrow.fill()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
  let bitmap = NSBitmapImageRep(data: tiff),
  let png = bitmap.representation(using: .png, properties: [:])
else {
  fatalError("Could not encode the app icon")
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "AppIcon.png")
try png.write(to: outputURL)
