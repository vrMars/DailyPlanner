import UIKit
import CoreGraphics

public enum SketchToolType {
    case pen
    case eraser
    case line
    case arrow
    case rectangleStroke
    case rectangleFill
    case ellipseStroke
    case ellipseFill
    case stamp
}

public enum ImageRenderingMode {
    case scale
    case original
}

@objc public protocol SketchViewDelegate: NSObjectProtocol  {
    @objc optional func drawView(_ view: SketchView, willBeginDrawUsingTool tool: AnyObject)
    @objc optional func drawView(_ view: SketchView, didEndDrawUsingTool tool: AnyObject)
}

public class SketchView: UIView {
    public var lineColor = UIColor.black
    public var lineWidth = CGFloat(10)
    public var lineAlpha = CGFloat(1)
    public var stampImage: UIImage?
    public var drawTool: SketchToolType = .pen
    public var sketchViewDelegate: SketchViewDelegate?
    public var paths: NSMutableArray = []
    private var currentTool: SketchTool?
    public var pathArray: NSMutableArray = NSMutableArray() {
        didSet {
            paths.add(pathArray.lastObject)
        }
    }
    private var removalArray: NSMutableArray = NSMutableArray()
    private let bufferArray: NSMutableArray = NSMutableArray()
    private var currentPoint: CGPoint?
    private var previousPoint1: CGPoint?
    private var previousPoint2: CGPoint?
    public var image: UIImage?
    public var backgroundImage: UIImage?
    private var drawMode: ImageRenderingMode = .scale

    public override init(frame: CGRect) {
        super.init(frame: frame)
        prepareForInitial()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        prepareForInitial()
    }

    private func prepareForInitial() {
        backgroundColor = UIColor.clear
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        image?.draw(in: self.bounds)

        currentTool?.draw()
    }

    private func updateCacheImage(_ isUpdate: Bool) {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)

        if isUpdate {
            image = nil
            (backgroundImage?.copy() as? UIImage)?.draw(in: self.bounds)

            for obj in pathArray {
                if let tool = obj as? PenTool {
                    tool.draw()
                }
            }
        } else {
            print("else")
            image?.draw(at: .zero)
            currentTool?.draw()
        }

        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }

    private func toolWithCurrentSettings() -> SketchTool? {
        switch drawTool {
        case .pen:
            return PenTool()
        case .eraser:
            return EraserTool()
        case .stamp:
            return StampTool()
        case .line:
            return LineTool()
        case .arrow:
            return ArrowTool()
        case .rectangleStroke:
            let rectTool = RectTool()
            rectTool.isFill = false
            return rectTool
        case .rectangleFill:
            let rectTool = RectTool()
            rectTool.isFill = true
            return rectTool
        case .ellipseStroke:
            let ellipseTool = EllipseTool()
            ellipseTool.isFill = false
            return ellipseTool
        case .ellipseFill:
            let ellipseTool = EllipseTool()
            ellipseTool.isFill = true
            return ellipseTool
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch.type == .pencil else {
            return
        }

        previousPoint1 = touch.previousLocation(in: self)
        currentPoint = touch.location(in: self)
        currentTool = toolWithCurrentSettings()
        currentTool?.lineWidth = lineWidth
        currentTool?.lineColor = lineColor
        currentTool?.lineAlpha = lineAlpha

        switch currentTool! {
        case is EraserTool:
            guard let currentTool = currentTool as? EraserTool else { return }
            currentTool.setInitialPoint(currentPoint!)
        case is PenTool:
            guard let penTool = currentTool as? PenTool else { return }
            pathArray.add(penTool)
            penTool.setInitialPoint(currentPoint!)
        case is StampTool:
            guard let stampTool = currentTool as? StampTool else { return }
            pathArray.add(stampTool)
            stampTool.setStampImage(image: stampImage)
            stampTool.setInitialPoint(currentPoint!)
        default:
            guard let currentTool = currentTool else { return }
            pathArray.add(currentTool)
            currentTool.setInitialPoint(currentPoint!)
        }

    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch.type == .pencil else { return }

        previousPoint2 = previousPoint1
        previousPoint1 = touch.previousLocation(in: self)
        currentPoint = touch.location(in: self)

        if let eraserTool = currentTool as? EraserTool {
            eraserTool.lineColor = .clear
            let _ = eraserTool.createBezierRenderingBox(previousPoint2!, widhPreviousPoint: previousPoint1!, withCurrentPoint: currentPoint!)

            for pen in pathArray {
                guard let pen = pen as? PenTool else { continue }
                if doBoundingBoxesIntersect(a: pen.path.cgPath.boundingBox, b: eraserTool.path.cgPath.boundingBox) {
                    removalArray.add(pen)
                }
            }

            for each in removalArray {
                if pathArray.count > pathArray.indexOfObjectIdentical(to: each) {
                    (pathArray.object(at: pathArray.indexOfObjectIdentical(to: each)) as! PenTool).lineColor = .red
                }
            }
            updateCacheImage(true)
            setNeedsDisplay()
        } else if let penTool = currentTool as? PenTool {
            let renderingBox = penTool.createBezierRenderingBox(previousPoint2!, widhPreviousPoint: previousPoint1!, withCurrentPoint: currentPoint!)
            setNeedsDisplay(renderingBox)
        }
        else {
            currentTool?.moveFromPoint(previousPoint1!, toPoint: currentPoint!)
            setNeedsDisplay()
        }
    }

    func doBoundingBoxesIntersect(a: CGRect, b: CGRect) -> Bool {
        return !a.intersection(b).isEmpty
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesMoved(touches, with: event)
        for each in removalArray {
            pathArray.removeObject(identicalTo: each)
        }
        setNeedsDisplay()
        finishDrawing()
    }

    fileprivate func finishDrawing() {
        updateCacheImage(removalArray.count == 0 ? false : true)
        removalArray.removeAllObjects()
        bufferArray.removeAllObjects()
        sketchViewDelegate?.drawView?(self, didEndDrawUsingTool: currentTool as AnyObject )
        currentTool = nil
    }

    private func resetTool() {
        currentTool = nil
    }

    public func clear() {
        resetTool()
        bufferArray.removeAllObjects()
        pathArray.removeAllObjects()
        updateCacheImage(true)

        setNeedsDisplay()
    }

    func pinch() {
        resetTool()
        guard let tool = pathArray.lastObject as? SketchTool else { return }
        bufferArray.add(tool)
        pathArray.removeLastObject()
        updateCacheImage(true)

        setNeedsDisplay()
    }

    public func loadImage(image: UIImage) {
        self.image = image
        backgroundImage = image.copy() as? UIImage
        bufferArray.removeAllObjects()
        pathArray.removeAllObjects()
        updateCacheImage(true)

        setNeedsDisplay()
    }

    public func loadPaths(bezPaths: [UIBezierPath]){
        //current tool?
        currentTool?.lineWidth = 10
        for each in bezPaths {
            currentTool = PenTool(path: each)
            pathArray.add(currentTool)
        }
        updateCacheImage(true)
        setNeedsDisplay()
        bufferArray.removeAllObjects()
    }

    public func undo() {
        if canUndo() {
            guard let tool = pathArray.lastObject as? SketchTool else { return }
            resetTool()
            bufferArray.add(tool)
            pathArray.removeLastObject()
            updateCacheImage(true)

            setNeedsDisplay()
        }
    }

    public func redo() {
        if canRedo() {
            guard let tool = bufferArray.lastObject as? SketchTool else { return }
            resetTool()
            pathArray.add(tool)
            bufferArray.removeLastObject()
            updateCacheImage(true)

            setNeedsDisplay()
        }
    }

    func canUndo() -> Bool {
        return pathArray.count > 0
    }

    func canRedo() -> Bool {
        return bufferArray.count > 0
    }
}
