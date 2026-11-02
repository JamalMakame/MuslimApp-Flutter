import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Run from the repository root: swift design/generate_app_icons.swift
// Keep the icon wordless: the gold mihrab and eight-point star echo Deen's splash.
private let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
private let colorSpace = CGColorSpaceCreateDeviceRGB()

private func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
  CGColor(colorSpace: colorSpace, components: [r / 255, g / 255, b / 255, a])!
}

private func gradient(_ colors: [CGColor]) -> CGGradient {
  CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: nil)!
}

private func drawBackground(_ context: CGContext) {
  context.drawLinearGradient(
    gradient([color(14, 107, 92), color(6, 53, 46)]),
    start: CGPoint(x: 88, y: 930),
    end: CGPoint(x: 915, y: 66),
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
  )
  // A restrained highlight gives the small flat surface a little depth.
  context.drawRadialGradient(
    gradient([color(157, 169, 112, 0.13), color(157, 169, 112, 0)]),
    startCenter: CGPoint(x: 512, y: 720), startRadius: 0,
    endCenter: CGPoint(x: 512, y: 720), endRadius: 680,
    options: []
  )
}

private func starPath() -> CGPath {
  let path = CGMutablePath()
  for point in 0..<16 {
    let angle = CGFloat(point) * .pi / 8 + .pi / 2
    let radius: CGFloat = point.isMultiple(of: 2) ? 84 : 39
    let position = CGPoint(
      x: 512 + cos(angle) * radius,
      y: 480 + sin(angle) * radius
    )
    if point == 0 { path.move(to: position) }
    else { path.addLine(to: position) }
  }
  path.closeSubpath()
  return path
}

private func makeMarkPath() -> CGPath {
  let outer = CGMutablePath()
  outer.move(to: CGPoint(x: 274, y: 248))
  outer.addLine(to: CGPoint(x: 274, y: 555))
  outer.addCurve(
    to: CGPoint(x: 512, y: 828),
    control1: CGPoint(x: 274, y: 692),
    control2: CGPoint(x: 447, y: 771)
  )
  outer.addCurve(
    to: CGPoint(x: 750, y: 555),
    control1: CGPoint(x: 577, y: 771),
    control2: CGPoint(x: 750, y: 692)
  )
  outer.addLine(to: CGPoint(x: 750, y: 248))
  outer.closeSubpath()

  let inner = CGMutablePath()
  inner.move(to: CGPoint(x: 356, y: 248))
  inner.addLine(to: CGPoint(x: 356, y: 557))
  inner.addCurve(
    to: CGPoint(x: 512, y: 720),
    control1: CGPoint(x: 356, y: 635),
    control2: CGPoint(x: 453, y: 675)
  )
  inner.addCurve(
    to: CGPoint(x: 668, y: 557),
    control1: CGPoint(x: 571, y: 675),
    control2: CGPoint(x: 668, y: 635)
  )
  inner.addLine(to: CGPoint(x: 668, y: 248))
  inner.closeSubpath()

  let shape = CGMutablePath()
  shape.addPath(outer)
  shape.addPath(inner)
  shape.addPath(starPath())
  shape.addPath(CGPath(roundedRect: CGRect(x: 255, y: 192, width: 514, height: 36),
                       cornerWidth: 18, cornerHeight: 18, transform: nil))
  return shape
}

private let markPath = makeMarkPath()

private func drawMark(_ context: CGContext, monochrome: Bool, scale: CGFloat = 1) {
  context.saveGState()
  context.translateBy(x: 512, y: 512)
  context.scaleBy(x: scale, y: scale)
  context.translateBy(x: -512, y: -512)
  context.addPath(markPath)
  context.clip(using: .evenOdd)
  if monochrome {
    context.setFillColor(color(255, 255, 255))
    context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
  } else {
    context.drawLinearGradient(
      gradient([color(241, 212, 136), color(201, 162, 75), color(176, 126, 45)]),
      start: CGPoint(x: 180, y: 835),
      end: CGPoint(x: 840, y: 185),
      options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
  }
  context.restoreGState()
}

private func render(_ pixels: Int, opaque: Bool, monochrome: Bool = false) -> Data {
  guard let context = CGContext(
    data: nil, width: pixels, height: pixels, bitsPerComponent: 8,
    bytesPerRow: 0, space: colorSpace,
    bitmapInfo: opaque ? CGImageAlphaInfo.noneSkipLast.rawValue
                       : CGImageAlphaInfo.premultipliedLast.rawValue
  ) else {
    fatalError("Cannot create icon context")
  }
  context.setShouldAntialias(true)
  context.interpolationQuality = .high
  context.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
  context.clear(CGRect(x: 0, y: 0, width: 1024, height: 1024))
  if opaque { drawBackground(context) }
  // flutter_launcher_icons applies the Android adaptive foreground's 16% inset.
  drawMark(context, monochrome: monochrome)
  let data = NSMutableData()
  guard let image = context.makeImage(),
        let output = CGImageDestinationCreateWithData(
          data as CFMutableData, UTType.png.identifier as CFString, 1, nil
        ) else {
    fatalError("Cannot encode icon PNG")
  }
  CGImageDestinationAddImage(output, image, nil)
  guard CGImageDestinationFinalize(output) else { fatalError("Cannot finish icon PNG") }
  return data as Data
}

private func write(_ data: Data, to path: String) throws {
  try data.write(to: root.appendingPathComponent(path))
  print(path)
}

private func svgPath(_ path: CGPath) -> String {
  var commands: [String] = []
  let locale = Locale(identifier: "en_US_POSIX")
  func coordinate(_ point: CGPoint) -> String {
    return "\(String(format: "%.2f", locale: locale, Double(point.x))) " +
           "\(String(format: "%.2f", locale: locale, Double(point.y)))"
  }
  path.applyWithBlock { pointer in
    let element = pointer.pointee
    switch element.type {
    case .moveToPoint:
      commands.append("M \(coordinate(element.points[0]))")
    case .addLineToPoint:
      commands.append("L \(coordinate(element.points[0]))")
    case .addQuadCurveToPoint:
      commands.append("Q \(coordinate(element.points[0])) \(coordinate(element.points[1]))")
    case .addCurveToPoint:
      commands.append(
        "C \(coordinate(element.points[0])) \(coordinate(element.points[1])) \(coordinate(element.points[2]))"
      )
    case .closeSubpath:
      commands.append("Z")
    @unknown default:
      fatalError("Unrecognized icon path element")
    }
  }
  return commands.joined(separator: " ")
}

let path = svgPath(markPath)
let header = #"<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">"#
let goldGradient = """
<defs><linearGradient id="gold" gradientUnits="userSpaceOnUse" x1="180" y1="189" x2="840" y2="839">
<stop stop-color="#F1D488"/><stop offset="0.5" stop-color="#C9A24B"/><stop offset="1" stop-color="#B07E2D"/>
</linearGradient></defs>
"""
let markGroup = #"<g transform="translate(0 1024) scale(1 -1)"><path fill-rule="evenodd" d=""#
let goldMark = "\(markGroup)\(path)\" fill=\"url(#gold)\"/></g>"
let whiteMark = "\(markGroup)\(path)\" fill=\"#FFFFFF\"/></g>"
let background = """
<defs><linearGradient id="bg" gradientUnits="userSpaceOnUse" x1="88" y1="94" x2="915" y2="958">
<stop stop-color="#0E6B5C"/><stop offset="1" stop-color="#06352E"/>
</linearGradient><radialGradient id="light" cx="512" cy="304" r="680" gradientUnits="userSpaceOnUse">
<stop stop-color="#9DA970" stop-opacity="0.13"/><stop offset="1" stop-color="#9DA970" stop-opacity="0"/>
</radialGradient></defs>
<rect width="1024" height="1024" fill="url(#bg)"/>
<rect width="1024" height="1024" fill="url(#light)"/>
"""
try write(Data("\(header)\n\(background)\n\(goldGradient)\n\(goldMark)\n</svg>\n".utf8),
          to: "assets/branding/app_icon.svg")
try write(Data("\(header)\n\(goldGradient)\n\(goldMark)\n</svg>\n".utf8),
          to: "assets/branding/app_icon_foreground.svg")
try write(Data("\(header)\n\(whiteMark)\n</svg>\n".utf8),
          to: "assets/branding/app_icon_monochrome.svg")
try write(render(1024, opaque: true), to: "assets/branding/app_icon.png")
try write(render(1024, opaque: false), to: "assets/branding/app_icon_foreground.png")
try write(render(1024, opaque: false, monochrome: true),
          to: "assets/branding/app_icon_monochrome.png")

let catalog = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
let contents = try JSONSerialization.jsonObject(
  with: Data(contentsOf: root.appendingPathComponent("\(catalog)/Contents.json"))
) as! [String: Any]
for image in contents["images"] as! [[String: String]] {
  let points = Double(image["size"]!.split(separator: "x")[0])!
  let scale = Double(image["scale"]!.replacingOccurrences(of: "x", with: ""))!
  try write(render(Int((points * scale).rounded()), opaque: true),
            to: "\(catalog)/\(image["filename"]!)")
}
try write(render(512, opaque: true), to: "design/app-icon-play-store.png")

// A review board pairs full-size system masks with actual launcher-size samples.
private func preview() -> Data {
  let width = 1280
  let height = 760
  guard let context = CGContext(
    data: nil, width: width, height: height, bitsPerComponent: 8,
    bytesPerRow: 0, space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
  ) else { fatalError("Cannot create icon preview") }
  context.setShouldAntialias(true)
  context.setFillColor(color(248, 246, 241))
  context.fill(CGRect(x: 0, y: 0, width: width, height: height))

  func label(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat,
             ink: CGColor = color(14, 74, 63)) {
    let attributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key(rawValue: kCTFontAttributeName as String):
        CTFontCreateWithName("AvenirNext-DemiBold" as CFString, size, nil),
      NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): ink
    ]
    let line = CTLineCreateWithAttributedString(
      NSAttributedString(string: text, attributes: attributes)
    )
    context.textPosition = CGPoint(x: x, y: y)
    CTLineDraw(line, context)
  }

  func tile(x: CGFloat, y: CGFloat, size: CGFloat, circle: Bool,
            adaptive: Bool = false, monochrome: Bool = false) {
    context.saveGState()
    let rect = CGRect(x: x, y: y, width: size, height: size)
    if circle { context.addEllipse(in: rect) }
    else {
      context.addPath(CGPath(roundedRect: rect, cornerWidth: size * 0.22,
                             cornerHeight: size * 0.22, transform: nil))
    }
    context.clip()
    context.translateBy(x: x, y: y)
    context.scaleBy(x: size / 1024, y: size / 1024)
    if adaptive {
      context.setFillColor(color(14, 107, 92))
      context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    } else {
      drawBackground(context)
    }
    drawMark(context, monochrome: monochrome, scale: adaptive ? 0.68 : 1)
    context.restoreGState()
  }

  label("DEEN  /  APP ICON", x: 96, y: 681, size: 29)
  context.setStrokeColor(color(201, 162, 75, 0.55))
  context.setLineWidth(1)
  context.move(to: CGPoint(x: 96, y: 655))
  context.addLine(to: CGPoint(x: 1184, y: 655))
  context.strokePath()

  label("iOS", x: 140, y: 602, size: 22)
  label("ANDROID  /  ADAPTIVE", x: 710, y: 602, size: 22)
  tile(x: 140, y: 237, size: 320, circle: false)
  tile(x: 710, y: 237, size: 320, circle: true, adaptive: true)
  label("Home screen  +  App Store", x: 140, y: 197, size: 14)
  label("Circle mask  +  themed mark", x: 710, y: 197, size: 14)

  tile(x: 140, y: 92, size: 60, circle: false)
  tile(x: 234, y: 92, size: 40, circle: false)
  tile(x: 308, y: 92, size: 29, circle: false)
  tile(x: 710, y: 92, size: 60, circle: true, adaptive: true)
  tile(x: 804, y: 92, size: 40, circle: true, adaptive: true)
  tile(x: 878, y: 92, size: 29, circle: true, adaptive: true)
  tile(x: 950, y: 92, size: 60, circle: true, adaptive: true, monochrome: true)
  label("60px", x: 140, y: 66, size: 13)
  label("40px", x: 234, y: 66, size: 13)
  label("29px", x: 308, y: 66, size: 13)
  label("60px", x: 710, y: 66, size: 13)
  label("40px", x: 804, y: 66, size: 13)
  label("29px", x: 878, y: 66, size: 13)
  label("MONO", x: 950, y: 66, size: 13)

  let data = NSMutableData()
  guard let image = context.makeImage(),
        let output = CGImageDestinationCreateWithData(
          data as CFMutableData, UTType.png.identifier as CFString, 1, nil
        ) else { fatalError("Cannot encode icon preview") }
  CGImageDestinationAddImage(output, image, nil)
  guard CGImageDestinationFinalize(output) else { fatalError("Cannot finish icon preview") }
  return data as Data
}
try write(preview(), to: "design/app-icon-preview.png")
