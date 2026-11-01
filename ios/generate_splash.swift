import AppKit

// Run from the repository root: swift ios/generate_splash.swift
// The same dome is used by the native launch artwork and Flutter splash.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let launchAssets = root.appendingPathComponent(
  "ios/Runner/Assets.xcassets/LaunchImage.imageset"
)
let flutterAssets = root.appendingPathComponent("assets/images")
let colorSpace = CGColorSpaceCreateDeviceRGB()

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat) -> CGColor {
  CGColor(colorSpace: colorSpace, components: [red / 255, green / 255, blue / 255, alpha])!
}

func gold(_ alpha: CGFloat = 1) -> CGColor { color(201, 162, 75, alpha) }

func dome(_ ctx: CGContext, at center: CGPoint) {
  ctx.saveGState()
  ctx.translateBy(x: center.x - 32, y: center.y - 32)
  ctx.setLineCap(.round)
  ctx.setLineJoin(.round)
  ctx.setStrokeColor(gold())
  ctx.setLineWidth(1.6)

  let arch = CGMutablePath()
  arch.move(to: CGPoint(x: 32, y: 14))
  arch.addCurve(
    to: CGPoint(x: 20, y: 34),
    control1: CGPoint(x: 29, y: 19),
    control2: CGPoint(x: 20, y: 23)
  )
  arch.addQuadCurve(to: CGPoint(x: 22, y: 44), control: CGPoint(x: 20, y: 41))
  arch.addLine(to: CGPoint(x: 42, y: 44))
  arch.addQuadCurve(to: CGPoint(x: 44, y: 34), control: CGPoint(x: 44, y: 41))
  arch.addCurve(
    to: CGPoint(x: 32, y: 14),
    control1: CGPoint(x: 44, y: 23),
    control2: CGPoint(x: 35, y: 19)
  )
  ctx.addPath(arch)
  ctx.strokePath()

  ctx.setStrokeColor(gold(0.55))
  ctx.setLineWidth(1)
  ctx.move(to: CGPoint(x: 26, y: 44))
  ctx.addQuadCurve(to: CGPoint(x: 32, y: 23), control: CGPoint(x: 24, y: 30))
  ctx.addQuadCurve(to: CGPoint(x: 38, y: 44), control: CGPoint(x: 40, y: 30))
  ctx.strokePath()

  ctx.setStrokeColor(gold())
  ctx.setLineWidth(1.5)
  ctx.move(to: CGPoint(x: 29, y: 44))
  ctx.addLine(to: CGPoint(x: 29, y: 37))
  ctx.addQuadCurve(to: CGPoint(x: 35, y: 37), control: CGPoint(x: 32, y: 31))
  ctx.addLine(to: CGPoint(x: 35, y: 44))
  ctx.move(to: CGPoint(x: 16, y: 44))
  ctx.addLine(to: CGPoint(x: 48, y: 44))
  ctx.move(to: CGPoint(x: 18, y: 48))
  ctx.addLine(to: CGPoint(x: 46, y: 48))
  ctx.move(to: CGPoint(x: 15, y: 44))
  ctx.addLine(to: CGPoint(x: 15, y: 34))
  ctx.addLine(to: CGPoint(x: 17, y: 31))
  ctx.addLine(to: CGPoint(x: 17, y: 44))
  ctx.move(to: CGPoint(x: 49, y: 44))
  ctx.addLine(to: CGPoint(x: 49, y: 34))
  ctx.addLine(to: CGPoint(x: 47, y: 31))
  ctx.addLine(to: CGPoint(x: 47, y: 44))
  ctx.move(to: CGPoint(x: 32, y: 14))
  ctx.addLine(to: CGPoint(x: 32, y: 10))
  ctx.strokePath()

  ctx.setFillColor(gold())
  ctx.fillEllipse(in: CGRect(x: 32, y: 6, width: 4, height: 4))
  ctx.restoreGState()
}

func emblem(_ ctx: CGContext) {
  let center = CGPoint(x: 104, y: 104)
  ctx.setStrokeColor(gold(0.3))
  ctx.setLineWidth(0.7)
  ctx.strokeEllipse(in: CGRect(x: 8, y: 8, width: 192, height: 192))
  ctx.strokeEllipse(in: CGRect(x: 14, y: 14, width: 180, height: 180))

  for angle in [CGFloat.zero, .pi / 4] {
    ctx.saveGState()
    ctx.translateBy(x: center.x, y: center.y)
    ctx.rotate(by: angle)
    ctx.stroke(CGRect(x: -64, y: -64, width: 128, height: 128))
    ctx.restoreGState()
  }

  ctx.setFillColor(color(10, 74, 63, 0.9))
  ctx.fillEllipse(in: CGRect(x: 40, y: 40, width: 128, height: 128))
  ctx.setStrokeColor(gold(0.4))
  ctx.strokeEllipse(in: CGRect(x: 40, y: 40, width: 128, height: 128))
  dome(ctx, at: center)
}

func render(_ points: Int, scale: Int, draw: (CGContext) -> Void) -> Data {
  let pixels = points * scale
  guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixels,
    pixelsHigh: pixels,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
  ), let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Could not create splash bitmap")
  }

  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = graphics
  let ctx = graphics.cgContext
  ctx.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
  ctx.translateBy(x: 0, y: CGFloat(points))
  ctx.scaleBy(x: 1, y: -1)
  ctx.clear(CGRect(x: 0, y: 0, width: points, height: points))
  draw(ctx)
  ctx.flush()
  NSGraphicsContext.restoreGraphicsState()
  guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode splash bitmap")
  }
  return png
}

for scale in 1...3 {
  let suffix = scale == 1 ? "" : "@\(scale)x"
  let file = launchAssets.appendingPathComponent("LaunchImage\(suffix).png")
  try render(208, scale: scale, draw: emblem).write(to: file)
  print(file.path)
}

let flutterMark = flutterAssets.appendingPathComponent("deen_dome.png")
try render(64, scale: 3) { dome($0, at: CGPoint(x: 32, y: 32)) }
  .write(to: flutterMark)
print(flutterMark.path)
