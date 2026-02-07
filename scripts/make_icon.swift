import AppKit

let size = 1024
let scale: CGFloat = 1
let rect = CGRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size))

let colorTop = NSColor(calibratedRed: 0.32, green: 0.80, blue: 0.78, alpha: 1)
let colorBottom = NSColor(calibratedRed: 0.06, green: 0.28, blue: 0.46, alpha: 1)
let colorMid = NSColor(calibratedRed: 0.18, green: 0.55, blue: 0.68, alpha: 1)

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: CGFloat(size), height: CGFloat(size))

NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSGraphicsContext.current?.imageInterpolation = .high

let ctx = NSGraphicsContext.current!.cgContext
ctx.setAllowsAntialiasing(true)
ctx.setShouldAntialias(true)

let inset: CGFloat = 64
let bgRect = rect.insetBy(dx: inset, dy: inset)
let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 200, yRadius: 200)

let gradient = NSGradient(colors: [colorTop, colorMid, colorBottom])!
gradient.draw(in: bgPath, angle: -90)

// Subtle highlight
let highlight = NSBezierPath(ovalIn: CGRect(x: bgRect.minX - 120, y: bgRect.maxY - 320, width: 420, height: 420))
NSColor.white.withAlphaComponent(0.18).setFill()
highlight.fill()

// Waveform bars
let centerY = bgRect.midY
let barCount = 7
let barWidth: CGFloat = 64
let spacing: CGFloat = 36
let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * spacing
let startX = bgRect.midX - totalWidth / 2
let heights: [CGFloat] = [200, 320, 440, 520, 440, 320, 200]

for i in 0..<barCount {
    let h = heights[i]
    let x = startX + CGFloat(i) * (barWidth + spacing)
    let rect = CGRect(x: x, y: centerY - h / 2, width: barWidth, height: h)
    let path = NSBezierPath(roundedRect: rect, xRadius: 32, yRadius: 32)
    NSColor.white.withAlphaComponent(0.92).setFill()
    path.fill()
}

if let data = rep.representation(using: .png, properties: [:]) {
    let url = URL(fileURLWithPath: "Resources/AppIcon.png")
    try data.write(to: url)
}
