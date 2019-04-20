//
//  Service.swift
//  AR Drawing
//
//  Created by Shawn Ma on 4/9/19.
//  Copyright © 2019 Shawn Ma. All rights reserved.
//

import Foundation
import ARKit

class Service: NSObject {
    
    public static let cameraRelativePosition = SCNVector3(0, 0, -0.1)
    
    public static let testPath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 0.05, height: 0.05))
    
//    public static func to3D(startPoint: SCNVector3, inView: ARSCNView, point: Point) -> SCNNode {
//
//    }
    
    public static func to2D(startPoint: SCNVector3, inView: ARSCNView) -> (x: Float, y: Float) {
        
        let planePos = startPoint
        let normalizedVector = SCNVector3Make(0, 0, 1)
        
        let nodePos = getPointerPosition(inView: inView, cameraRelativePosition: self.cameraRelativePosition).pos - planePos
        let camPos = getPointerPosition(inView: inView, cameraRelativePosition: self.cameraRelativePosition).camPos - planePos

        let target = nodePos - planePos
        let dist = target * normalizedVector

        let x = (nodePos.x - camPos.x) * (dist.length() / nodePos.z) + camPos.x
        let y = (nodePos.y - camPos.y) * (dist.length() / nodePos.z) + camPos.y
        
        log.debug(x)
        log.debug(y)
        
        return (x, y)
    }
    
    public static func getPointerPosition(inView: ARSCNView, cameraRelativePosition: SCNVector3) -> (pos : SCNVector3, valid: Bool, camPos : SCNVector3) {
        
        guard let pointOfView = inView.pointOfView else { return (SCNVector3Zero, false, SCNVector3Zero) }
        
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let currentPositionOfCamera = orientation + location
        
        let pointerPosition = currentPositionOfCamera + cameraRelativePosition
        
        return (pointerPosition, true, currentPositionOfCamera)
    }
    
    public static func addNode(_ node: SCNNode, toNode: SCNNode, inView: ARSCNView, cameraRelativePosition: SCNVector3) {
        
        guard let currentFrame = inView.session.currentFrame else { return }
        let camera = currentFrame.camera
        let transform = camera.transform
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.x = cameraRelativePosition.x
        translationMatrix.columns.3.y = cameraRelativePosition.y
        translationMatrix.columns.3.z = cameraRelativePosition.z
        let modifiedMatrix = simd_mul(transform, translationMatrix)
        node.simdTransform = modifiedMatrix
        DispatchQueue.main.async {
            toNode.addChildNode(node)
        }
    }
    
    static func fadeViewInThenOut(view : UIView, delay: TimeInterval) {
        
        let animationDuration = 1.5
        
        // Fade in the view
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            view.alpha = 1
        }) { (Bool) -> Void in
            
            UIView.animate(withDuration: animationDuration, delay: delay, options: .curveEaseInOut, animations: { () -> Void in
                view.alpha = 0
            }, completion: nil)
        }
    }

}

//MARK:- 3D shapes go here
extension Service {
    
    
    static func get3DShapeNode(forShape shape: Shape) -> SCNNode? {
        guard let path = self.generatePath(forShape: shape) else {return nil}
        switch shape.name {
        case "circle":
            return Circle(path: path)
        default:
            return nil
        }
    }
    
    private static func generatePath(forShape shape: Shape) -> UIBezierPath? {
        switch shape.name {
        case "circle":
            return self.computeCircle(shape: shape)
        default:
            return nil
        }
    }
    
    private static func computeCircle(shape: Shape) -> UIBezierPath? {
        guard let center = shape.center else {return nil}
        guard let firstPoint = shape.points.first else {return nil}
        let radius = Point.distanceBetween(pointA: firstPoint, pointB: center) / 10
        log.debug(radius)
        
//        let strokeBezierPath = UIBezierPath(arcCenter: .zero, radius: radius/10, startAngle: .zero, endAngle: CGFloat(Double.pi * 2), clockwise: true)
//        strokeBezierPath.lineWidth = 0.01
        let strokeBezierPath = UIBezierPath(ovalIn: CGRect(x: -radius, y: -radius, width: 2 *  radius, height: 2 * radius))
        strokeBezierPath.lineWidth = 0.01

//                let strokeBezierPath = UIBezierPath()
//                strokeBezierPath.lineWidth = 0.01
//                strokeBezierPath.move(to: CGPoint.zero)
//                strokeBezierPath.addLine(to: CGPoint(x: radius, y: 0))
//                strokeBezierPath.addLine(to: CGPoint(x: radius, y: radius))
//                strokeBezierPath.addLine(to: CGPoint(x: 0.0, y: radius))
//                strokeBezierPath.addLine(to: CGPoint(x: 0, y: 0))
//                strokeBezierPath.close()
        
        let cgPath = strokeBezierPath.cgPath.copy(
            strokingWithWidth: strokeBezierPath.lineWidth,
            lineCap: strokeBezierPath.lineCapStyle,
            lineJoin: strokeBezierPath.lineJoinStyle,
            miterLimit: strokeBezierPath.miterLimit)
        
        let path = UIBezierPath(cgPath: cgPath)
        
        return path
    }
}
