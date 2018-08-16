//
//  RulerViewController.swift
//  Ruler 3D AR
//
//  Created by Aaron John on 8/4/18.
//  Copyright © 2018 Aaron John. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import PKHUD
import AwesomeIntroGuideView

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var indicator: UIImageView!
    @IBOutlet var distanceLabel_Center: UILabel!
    @IBOutlet var placeButton: UIButton!
    @IBOutlet var trashButton: UIButton!
    @IBOutlet var settingButton: UIButton!
    @IBOutlet var sceneView: ARSCNView!
    
    var startNode: SCNNode!
    var endNode: SCNNode!
    var lineNode: SCNNode?
    var textNode: SCNNode!
    var textWrapNode: SCNNode!
    
    /*****/

    var center : CGPoint!
    
    let arrow = SCNScene(named: "art.scnassets/arrow.scn")!.rootNode

//    var cameraNode: SCNNode!
//    var linesNode: SCNNode?

    var positions = [SCNVector3]()

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let hitTest = sceneView.hitTest(center, types: .featurePoint)
        let result = hitTest.last
        guard let transform = result?.worldTransform else {return}
        let thirdColumn = transform.columns.3
        let position = SCNVector3Make(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        positions.append(position)
        let lastTenPositions = positions.suffix(10)
        arrow.position = getAveragePosition(from: lastTenPositions)
        
    }
    
    func getAveragePosition(from positions : ArraySlice<SCNVector3>) -> SCNVector3 {
        var averageX : Float = 0
        var averageY : Float = 0
        var averageZ : Float = 0

        for position in positions {
            averageX += position.x
            averageY += position.y
            averageZ += position.z
        }
        let count = Float(positions.count)
        return SCNVector3Make(averageX / count , averageY / count, averageZ / count)
    }


    var isFirstPoint = true
    var points = [SCNNode]()

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        center = view.center
        sceneView.scene.rootNode.addChildNode(arrow)
        sceneView.autoenablesDefaultLighting = true
    }

    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        center = view.center
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    @IBAction func placeAction(_ sender: UIButton) {
        
        let sphereGeometry = SCNSphere(radius: 0.005)
        let sphereNode = SCNNode(geometry: sphereGeometry)
        sphereNode.position = arrow.position
        sceneView.scene.rootNode.addChildNode(sphereNode)
        points.append(sphereNode)
        
        if isFirstPoint {
            isFirstPoint = false
        } else {
            //calculate the distance
            let pointA = points[points.count - 2]
            guard let pointB = points.last else {return}
            
            let d = distance(float3(pointA.position), float3(pointB.position))
            
//             add line
                let line = SCNGeometry.lined(from: pointA.position, to: pointB.position)
                print(d.description)
                let lineNode = SCNNode(geometry: line)
                sceneView.scene.rootNode.addChildNode(lineNode)
            
            
            // add midPoint
            let midPoint = (float3(pointA.position) + float3(pointB.position)) / 2
            let midPointGeometry = SCNSphere(radius: 0.003)
            midPointGeometry.firstMaterial?.diffuse.contents = UIColor.red
            let midPointNode = SCNNode(geometry: midPointGeometry)
            midPointNode.position = SCNVector3Make(midPoint.x, midPoint.y, midPoint.z)
            sceneView.scene.rootNode.addChildNode(midPointNode)
            
            // add text
            
            let textGeometry = SCNText(string: String(format: "%.0f", d * 100) + "cm" , extrusionDepth: 1)
            let textNode = SCNNode(geometry: textGeometry)
            textNode.scale = SCNVector3Make(0.005, 0.005, 0.01)
            textGeometry.flatness = 0.2
            midPointNode.addChildNode(textNode)
            
            
            // Billboard contraints
            let contraints = SCNBillboardConstraint()
            contraints.freeAxes = .all
            midPointNode.constraints = [contraints]
            
            
            isFirstPoint = true
            
            
        }
        
        
    }
    
    
    @IBAction func deleteAction(_ sender: UIButton) {
       
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        
    }
    
    @IBAction func toggleTorch(_ sender: UIButton) {
        
        guard let device = AVCaptureDevice.default(for: AVMediaType.video)
            else {return}
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if device.torchMode == .on {
                    device.torchMode = .off
                } else {
                    device.torchMode = .on
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    
    
}


extension SCNGeometry {
    class func lined(from vectorA : SCNVector3, to vectorB : SCNVector3) -> SCNGeometry {
        let indices : [Int32] = [0,1]
        let source = SCNGeometrySource(vertices: [vectorA, vectorB])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
}
