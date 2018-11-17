/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The view that is responsible for the drawing. StrokeCGView can draw a StrokeCollection as .ink
*/

import UIKit


enum StrokeViewDisplayOptions {
    case ink
}


class StrokeCGView: UIView {
    var displayOptions = StrokeViewDisplayOptions.ink {
        didSet {
            if strokeCollection != nil {
                setNeedsDisplay()
            }
            for view in dirtyRectViews {
                view.isHidden = true
            }
        }
    }
    
    var strokeCollection: StrokeCollection? {
        didSet {
            if oldValue !== strokeCollection {
                setNeedsDisplay()
            }
            if let lastStroke = strokeCollection?.strokes.last {
                setNeedsDisplay(for: lastStroke)
            }
            strokeToDraw = strokeCollection?.activeStroke
        }
    }
    
    var strokeToDraw: Stroke? {
        didSet {
            if oldValue !== strokeToDraw && oldValue != nil {
                setNeedsDisplay()
            } else {
                if let stroke = strokeToDraw {
                    setNeedsDisplay(for: stroke)
                }
            }
        }
    }
    
    // MARK: Dirty rect calculation and handling.
    var dirtyRectViews: [UIView]!
    var lastEstimatedSample: (Int, StrokeSample)?
    
    func dirtyRects(for stroke:Stroke) -> [CGRect] {
        var result = [CGRect]()
        for range in stroke.updatedRanges() {
            var lowerBound = range.lowerBound
            if lowerBound > 0 { lowerBound -= 1 }
            
            if let (index, _) = lastEstimatedSample {
                if index < lowerBound {
                    lowerBound = index
                }
            }
            
            let samples = stroke.samples
            var upperBound = range.upperBound
            if upperBound < samples.count { upperBound += 1 }
            let dirtyRect = dirtyRectForSampleStride(stroke.samples[lowerBound..<upperBound])
            result.append(dirtyRect)
        }
        if stroke.predictedSamples.count > 0 {
            let dirtyRect = dirtyRectForSampleStride(stroke.predictedSamples[0..<stroke.predictedSamples.count])
            result.append(dirtyRect)
        }
        if let previousPredictedSamples = stroke.previousPredictedSamples {
            let dirtyRect = dirtyRectForSampleStride(previousPredictedSamples[0..<previousPredictedSamples.count])
            result.append(dirtyRect)
        }
        return result
    }

    func dirtyRectForSampleStride(_ sampleStride: ArraySlice<StrokeSample>) -> CGRect {
        var first = true
        var frame = CGRect.zero
        for sample in sampleStride {
            let sampleFrame = CGRect(origin: sample.location, size: .zero)
            if first {
                first = false
                frame = sampleFrame
            } else {
                frame = frame.union(sampleFrame)
            }
        }
        let maxStrokeWidth = CGFloat(20.0)
        return frame.insetBy(dx: -1 * maxStrokeWidth, dy: -1 * maxStrokeWidth)
    }

    func setNeedsDisplay(for stroke:Stroke) {
        for dirtyRect in dirtyRects(for: stroke) {
            setNeedsDisplay(dirtyRect)
        }
    }
    
    // MARK: Inits
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.drawsAsynchronously = true

        let dirtyRectView = { () -> UIView in
            let view = UIView(frame: CGRect(x: -10, y: -10, width: 0, height: 0))
            view.layer.borderColor = UIColor.red.cgColor
            view.layer.borderWidth = 0.5
            view.isUserInteractionEnabled = false
            view.isHidden = true
            self.addSubview(view)
            return view
        }
        dirtyRectViews = [dirtyRectView(), dirtyRectView()]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // MARK: Drawing methods.
    
    
    /**
        Note: this is not a particularily efficient way to draw a great stroke path
        with CoreGraphics. It is just a way to produce an interesting looking result.
        For a real world example you would reuse and cache CGPaths and draw longer
        paths instead of an aweful lot of tiny ones, etc. You would also respect the 
        draw rect to cull your draw requests. And you would use bezier paths to
        interpolate between the points to get a smooother curve.
     */
    func draw(stroke: Stroke, in rect:CGRect, isActive active: Bool) {
        let displayOptions = self.displayOptions
        
        let updateRanges = stroke.updatedRanges()
        
        lastEstimatedSample = nil
        stroke.clearUpdateInfo()
        let sampleCount = stroke.samples.count
        guard sampleCount > 0 else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let strokeColor = UIColor.black
        
        let lineSettings: (()->())
        let forceEstimatedLineSettings: (()->())
        lineSettings = {
            context.setLineWidth(0.25)
            context.setStrokeColor(strokeColor.cgColor)
        }
        forceEstimatedLineSettings = lineSettings
        
        let azimuthSettings = {
            context.setLineWidth(1.5)
            context.setStrokeColor(UIColor.orange.cgColor)
        }
        let altitudeSettings = {
            context.setLineWidth(0.5)
            context.setStrokeColor(strokeColor.cgColor)
        }
        var forceMultiplier = CGFloat(2.0)
        var forceOffset = CGFloat(0.1)
        
        let fillColorRegular = UIColor.black.cgColor
        let fillColorCoalesced = UIColor.lightGray.cgColor
        let fillColorPredicted = UIColor.red.cgColor
        
        var lockedAzimuthUnitVector: CGVector?
        let azimuthLockAltitudeThreshold = CGFloat.pi / 2.0 * 0.80 // locking azimuth at 80% altitude
        
        lineSettings()
        
//        var forceAccessBlock = {(sample: StrokeSample) -> CGFloat in
//            sample.forceWithDefault
//        }

//        if displayOptions == .ink {
//            forceAccessBlock = {(sample: StrokeSample) -> CGFloat in
//                return sample.perpendicularForce
//            }
//        }
//
//        let previousGetter = forceAccessBlock
//        forceAccessBlock = {(sample: StrokeSample) -> CGFloat in
//            return previousGetter(sample) * forceMultiplier + forceOffset
//        }
        
        var heldFromSample: StrokeSample?
        var heldFromSampleUnitVector: CGVector?
        
        func draw(segment: StrokeSegment) {
            if let toSample = segment.toSample {
                let fromSample: StrokeSample = heldFromSample ?? segment.fromSample
                
                // Skip line segments that are too short.
                if (fromSample.location - toSample.location).quadrance < 0.003 {
                    if heldFromSample == nil {
                        heldFromSample = fromSample
                        heldFromSampleUnitVector = segment.fromSampleUnitNormal
                    }
                    return
                }
                
                context.setFillColor(fillColorRegular)
                
                
                let fromUnitVector = (heldFromSampleUnitVector != nil ? heldFromSampleUnitVector! : segment.fromSampleUnitNormal)
                let toUnitVector = segment.toSampleUnitNormal
                
//                let isForceEstimated = fromSample.estimatedProperties.contains(.force) || toSample.estimatedProperties.contains(.force)
//                if isForceEstimated {
//                    if lastEstimatedSample == nil {
//                        lastEstimatedSample = (segment.fromSampleIndex+1,toSample)
//                    }
//                    forceEstimatedLineSettings()
//                } else {
                    lineSettings()
              //  }
                
                context.beginPath()
                context.move(to: fromSample.location + fromUnitVector)
                context.addLine(to: toSample.location + toUnitVector)
                context.addLine(to: toSample.location - toUnitVector)
                context.addLine(to: fromSample.location - fromUnitVector)
                context.closePath()
                context.drawPath(using: .fillStroke)
                
                if heldFromSample != nil {
                    heldFromSample = nil
                    heldFromSampleUnitVector = nil
                }
            }
        }
        
        if stroke.samples.count == 1 {
            // Construct a face segment to draw for a stroke that is only one point.
            let sample = stroke.samples.first!
            let tempSampleFrom = StrokeSample(location: sample.location + CGVector(dx: -0.5, dy: 0.0))
            let tempSampleTo = StrokeSample(location: sample.location + CGVector(dx: 0.5, dy: 0.0))
            let segment = StrokeSegment(sample: tempSampleFrom)
            segment.advanceWithSample(incomingSample: tempSampleTo)
            segment.advanceWithSample(incomingSample: nil)

            draw(segment: segment)
        } else {
            for segment in stroke {
                draw(segment:segment)
            }
        }
        
    }
    
    override func draw(_ rect: CGRect) {
        //background color for view
        UIColor.white.set()
        UIRectFill(rect)
        
        // Optimization opportunity: Draw the existing collection in a different view, 
        // and only draw each time we add a stroke.
        if let strokeCollection = strokeCollection {
            for stroke in strokeCollection.strokes {
                draw(stroke: stroke, in: rect, isActive: false)
            }
        }
        
        if let stroke = strokeToDraw {
            draw(stroke: stroke, in: rect, isActive: true)
        }
    }
    
}
