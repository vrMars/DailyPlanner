import UIKit

protocol SketchTool {
    var lineWidth: CGFloat { get set }
    var lineColor: UIColor { get set }
    var lineAlpha: CGFloat { get set }

    func setInitialPoint(_ firstPoint: CGPoint)
    func moveFromPoint(_ startPoint: CGPoint, toPoint endPoint: CGPoint)
    func draw()
}

public class PenTool: UIBezierPath, SketchTool {
    var path: UIBezierPath
    var lineColor: UIColor
    var lineAlpha: CGFloat

    override init() {
        path = UIBezierPath.init()
        lineColor = .black
        lineAlpha = 1.0
        super.init()
        lineCapStyle = CGLineCap.round
    }

    init(path: UIBezierPath) {
        self.path = path
        lineColor = .black
        lineAlpha = 1.0
        super.init()
        lineCapStyle = CGLineCap.round
        lineWidth = path.lineWidth
    }

    required init?(coder aDecoder: NSCoder) {
        self.path = aDecoder.decodeObject(of: UIBezierPath.self, forKey: "path") ?? UIBezierPath.init()
        self.lineColor = aDecoder.decodeObject(of: UIColor.self, forKey: "color") ?? .green
        self.lineAlpha = aDecoder.decodeObject(forKey: "alpha") as? CGFloat ?? 1.0
        super.init(coder: aDecoder)
        lineWidth = path.lineWidth
    }

    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(self.path, forKey: "path")
        aCoder.encode(self.lineColor, forKey: "color")
        aCoder.encode(self.lineAlpha, forKey: "alpha")
    }

    func setInitialPoint(_ firstPoint: CGPoint) {}

    func moveFromPoint(_ startPoint: CGPoint, toPoint endPoint: CGPoint) {}

    func createBezierRenderingBox(_ previousPoint2: CGPoint, widhPreviousPoint previousPoint1: CGPoint, withCurrentPoint cpoint: CGPoint) -> CGRect {
        let mid1 = middlePoint(previousPoint1, previousPoint2: previousPoint2)
        let mid2 = middlePoint(cpoint, previousPoint2: previousPoint1)
        let subpath = UIBezierPath.init()

        subpath.move(to: CGPoint(x: mid1.x, y: mid1.y))
        subpath.addQuadCurve(to: CGPoint(x: mid2.x, y: mid2.y), controlPoint: CGPoint(x: previousPoint1.x, y: previousPoint1.y))
        path.append(subpath)
        
        var boundingBox: CGRect = subpath.cgPath.boundingBox
        boundingBox.origin.x -= lineWidth * 2.0
        boundingBox.origin.y -= lineWidth * 2.0
        boundingBox.size.width += lineWidth * 4.0
        boundingBox.size.height += lineWidth * 4.0
        return boundingBox
    }

    private func middlePoint(_ previousPoint1: CGPoint, previousPoint2: CGPoint) -> CGPoint {
        return CGPoint(x: (previousPoint1.x + previousPoint2.x) * 0.5, y: (previousPoint1.y + previousPoint2.y) * 0.5)
    }
    
    func draw() {
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.addPath(path.cgPath)
        context.setLineCap(.round)
        context.setLineWidth(path.lineWidth)
        context.setStrokeColor(lineColor.cgColor)
        context.setBlendMode(.normal)
        context.setAlpha(1.0)
        context.strokePath()
        path.lineWidth = lineWidth
    }
}

class EraserTool: PenTool {
    override func draw() {
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.saveGState()
        context.addPath(path.cgPath)
        context.setLineCap(.round)
        context.setLineWidth(path.lineWidth)
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setAlpha(0.5)
        context.setBlendMode(.normal)
        context.strokePath()
        context.restoreGState()
    }
}

class LineTool: SketchTool {
    var lineWidth: CGFloat
    var lineColor: UIColor
    var lineAlpha: CGFloat
    var firstPoint: CGPoint
    var lastPoint: CGPoint

    init() {
        lineWidth = 1.0
        lineAlpha = 1.0
        lineColor = .blue
        firstPoint = CGPoint(x: 0, y: 0)
        lastPoint = CGPoint(x: 0, y: 0)
    }

    internal func setInitialPoint(_ firstPoint: CGPoint) {
        self.firstPoint = firstPoint
    }

    internal func moveFromPoint(_ startPoint: CGPoint, toPoint endPoint: CGPoint) {
        self.lastPoint = endPoint
    }

    internal func draw() {
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setStrokeColor(lineColor.cgColor)
        context.setLineCap(.square)
        context.setLineWidth(lineWidth)
        context.setAlpha(lineAlpha)
        context.move(to: CGPoint(x: firstPoint.x, y: firstPoint.y))
        context.addLine(to: CGPoint(x: lastPoint.x, y: lastPoint.y))
        context.strokePath()
    }

    func angleWithFirstPoint(first: CGPoint, second: CGPoint) -> Float {
        let dx: CGFloat = second.x - first.x
        let dy: CGFloat = second.y - first.y
        let angle = atan2f(Float(dy), Float(dx))

        return angle
    }

    func pointWithAngle(angle: CGFloat, distance: CGFloat) -> CGPoint {
        let x = Float(distance) * cosf(Float(angle))
        let y = Float(distance) * sinf(Float(angle))

        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}

class ArrowTool: SketchTool {
    var lineWidth: CGFloat
    var lineColor: UIColor
    var lineAlpha: CGFloat
    var firstPoint: CGPoint
    var lastPoint: CGPoint

    init() {
        lineWidth = 1.0
        lineAlpha = 1.0
        lineColor = .black
        firstPoint = CGPoint(x: 0, y: 0)
        lastPoint = CGPoint(x: 0, y: 0)
    }

    func setInitialPoint(_ firstPoint: CGPoint) {
        self.firstPoint = firstPoint
    }

    func moveFromPoint(_ startPoint: CGPoint, toPoint endPoint: CGPoint) {
        lastPoint = endPoint
    }

    func draw() {
        let context: CGContext = UIGraphicsGetCurrentContext()!
        let capHeight = lineWidth * 4.0
        let angle = angleWithFirstPoint(first: firstPoint, second: lastPoint)
        var point1 = pointWithAngle(angle: CGFloat(angle + Float(6.0 * .pi / 8.0)), distance: capHeight)
        var point2 = pointWithAngle(angle:  CGFloat(angle - Float(6.0 * .pi / 8.0)), distance: capHeight)
        let endPointOffset = pointWithAngle(angle: CGFloat(angle), distance: lineWidth)

        context.setStrokeColor(lineColor.cgColor)
        context.setLineCap(.square)
        context.setLineWidth(lineWidth)
        context.setAlpha(lineAlpha)
        context.move(to: CGPoint(x: firstPoint.x, y: firstPoint.y))
        context.addLine(to: CGPoint(x: lastPoint.x, y: lastPoint.y))

        point1 = CGPoint(x: lastPoint.x + point1.x, y: lastPoint.y + point1.y)
        point2 = CGPoint(x: lastPoint.x + point2.x, y: lastPoint.y + point2.y)

        context.move(to: CGPoint(x: point1.x, y: point1.y))
        context.addLine(to: CGPoint(x: lastPoint.x + endPointOffset.x, y: lastPoint.y + endPointOffset.y))
        context.addLine(to: CGPoint(x: point2.x, y: point2.y))
        context.strokePath()
    }

    func angleWithFirstPoint(first: CGPoint, second: CGPoint) -> Float {
        let dx: CGFloat = second.x - first.x
        let dy: CGFloat = second.y - first.y
        let angle = atan2f(Float(dy), Float(dx))

        return angle
    }

    func pointWithAngle(angle: CGFloat, distance: CGFloat) -> CGPoint {
        let x = Float(distance) * cosf(Float(angle))
        let y = Float(distance) * sinf(Float(angle))

        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}

class RectTool: SketchTool {
    var lineWidth: CGFloat
    var lineAlpha: CGFloat
    var lineColor: UIColor
    var firstPoint: CGPoint
    var lastPoint: CGPoint
    var isFill: Bool

    init() {
        lineWidth = 1.0
        lineAlpha = 1.0
        lineColor = .blue
        firstPoint = CGPoint(x: 0, y: 0)
        lastPoint = CGPoint(x: 0, y: 0)
        isFill = false
    }

    internal func setInitialPoint(_ firstPoint: CGPoint) {
        self.firstPoint = firstPoint
    }

    internal func moveFromPoint(_ startPoint: CGPoint, toPoint endPoint: CGPoint) {
        self.lastPoint = endPoint
    }

    internal func draw() {
        let context: CGContext = UIGraphicsGetCurrentContext()!
        let rectToFill = CGRect(x: firstPoint.x, y: firstPoint.y, width: lastPoint.x - self.firstPoint.x, height: lastPoint.y - firstPoint.y)
        
        context.setAlpha(lineAlpha)
        if self.isFill {
            context.setFillColor(lineColor.cgColor)
            UIGraphicsGetCurrentContext()!.fill(rectToFill)
        } else {
            context.setStrokeColor(lineColor.cgColor)
            context.setLineWidth(lineWidth)
            UIGraphicsGetCurrentContext()!.stroke(rectToFill)
        }
    }
}

class EllipseTool: SketchTool {
    var eraserWidth: CGFloat
    var lineWidth: CGFloat
    var lineAlpha: CGFloat
    var lineColor: UIColor
    var firstPoint: CGPoint
    var lastPoint: CGPoint
    var isFill: Bool

    init() {
        eraserWidth = 0
        lineWidth = 1.0
        lineAlpha = 1.0
        lineColor = .blue
        firstPoint = CGPoint(x: 0, y: 0)
        lastPoint = CGPoint(x: 0, y: 0)
        isFill = false
    }

    internal func setInitialPoint(_ firstPoint: CGPoint) {
        self.firstPoint = firstPoint
    }

    internal func moveFromPoint(_ startPoint: CGPoint, toPoint endPoint: CGPoint) {
        lastPoint = endPoint
    }

    internal func draw() {
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setAlpha(lineAlpha)
        context.setLineWidth(lineWidth)
        let rectToFill = CGRect(x: firstPoint.x, y: firstPoint.y, width: lastPoint.x - self.firstPoint.x, height: lastPoint.y - firstPoint.y)
        if self.isFill {
            context.setFillColor(lineColor.cgColor)
            UIGraphicsGetCurrentContext()!.fillEllipse(in: rectToFill)
        } else {
            context.setStrokeColor(lineColor.cgColor)
            UIGraphicsGetCurrentContext()!.strokeEllipse(in: rectToFill)
        }
    }
}

class StampTool: SketchTool {
    var lineWidth: CGFloat
    var lineColor: UIColor
    var lineAlpha: CGFloat
    var touchPoint: CGPoint
    var stampImage: UIImage?

    init() {
        lineWidth = 0
        lineColor = .blue
        lineAlpha = 0
        touchPoint = CGPoint(x: 0, y: 0)
    }

    func setInitialPoint(_ firstPoint: CGPoint) {
        touchPoint = firstPoint
    }

    func moveFromPoint(_ startPoint: CGPoint, toPoint endPoint: CGPoint) {}

    func setStampImage(image: UIImage?) {
        if let image = image {
            stampImage = image
        }
    }

    func getStamImage() -> UIImage? {
        return stampImage
    }

    func draw() {
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setShadow(offset: CGSize(width :0, height: 0), blur: 0, color: nil)

        if let image = self.getStamImage() {
            let imageX = touchPoint.x  - (image.size.width / 2.0)
            let imageY = touchPoint.y - (image.size.height / 2.0)
            let imageWidth = image.size.width
            let imageHeight = image.size.height

            image.draw(in: CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight))
        }
    }
}
