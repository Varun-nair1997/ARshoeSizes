//
//  ViewController.swift
//  AR2
//
//  Created by Varun Nair on 3/4/20.
//  Copyright © 2020 Varun Nair. All rights reserved.
//

import UIKit
import ARKit
import SceneKit


class ViewController: UIViewController, ARSCNViewDelegate
{
    let SSC = shoeSizeEst()
    @IBOutlet weak var sizeLbl: UILabel!
    var startNode: SCNNode?
    var line_node: SCNNode?
    var dictPlanes = [ARPlaneAnchor: Plane]()

    @IBOutlet weak var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setupScene()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        self.setUpARSession()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        sceneView.session.pause()
    }
    
    func setupScene()
    {
        self.sceneView.delegate = self
        self.sceneView.showsStatistics = true
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        let scene = SCNScene()
        self.sceneView.scene = scene
        
    }
    
    func setupARSession()
    {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
    }
    
    func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3
    {
        return SCNVector3Make(transform.columns.3.x,transform.columns.3.y, transform.columns.3.z)
    }
    
    func doHitTestOnExistingPlanes() -> SCNVector3? {
        // hit-test of view's center with existing-planes
        let results = sceneView.hitTest(view.center,
                                        types: .existingPlaneUsingExtent)
        // check if result is available
        if let result = results.first {
            // get vector from transform
            let hitPos = self.positionFromTransform(result.worldTransform)
            return hitPos
        }
        return nil
    }
    
    func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry
    {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
    
    func getDrawnLineFrom(pos1: SCNVector3, toPos2: SCNVector3) -> SCNNode
    {
        let line = lineFrom(vector: pos1, toVector: toPos2)
        let lineInBetween1 = SCNNode(geometry: line)
        return lineInBetween1
    }
    
    func stringValue(v: Float, unit: String) -> String
    {
        let s = String(format: "%.1f %@", v, unit)
        return s
    }
    
    func distanceBetweenPoints(A: SCNVector3, B: SCNVector3) -> CGFloat
    {
//        heron's forumla
        let l = sqrt((A.x - B.x) * (A.x - B.x)   +   (A.y - B.y) * (A.y - B.y)   +   (A.z - B.z) * (A.z - B.z))
        return CGFloat(l)
    }
    
    func Inch_fromMeter(m: Float) -> Float
    {
        let v = m * 39.3701
        return v
        
    }
    
    func getDistanceStringBeween(pos1: SCNVector3?,
                                 pos2: SCNVector3?) -> String {
        
        if pos1 == nil || pos2 == nil {
            return "0"
        }
        let d = self.distanceBetweenPoints(A: pos1!, B: pos2!)
        
        var result = ""
        
        let inch = self.Inch_fromMeter(m: Float(d))
        let inches = stringValue(v: Float(inch), unit: "inch")
        result.append(inches)
        result.append("\n")
        
        return result
    }
    
    func getDistanceBeweeninINCHES(pos1: SCNVector3?, pos2: SCNVector3?) -> Float
    {
        if pos1 == nil || pos2 == nil {
            return 0.0
        }
        let d = self.distanceBetweenPoints(A: pos1!, B: pos2!)
        
        let inch = self.Inch_fromMeter(m: Float(d))
        return inch
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
    {
        DispatchQueue.main.async {
            // get current hit position
            // and check if start-node is available
            guard let currentPosition = self.doHitTestOnExistingPlanes(),
                let start = self.startNode else {
                    return
            }
            
            // line-node
            self.line_node?.removeFromParentNode()
            self.line_node = self.getDrawnLineFrom(pos1: currentPosition, toPos2: start.position)
            self.sceneView.scene.rootNode.addChildNode(self.line_node!)
            
            let inScore = self.getDistanceBeweeninINCHES(pos1: currentPosition, pos2: start.position)
            let shoesize = self.SSC.shoeSizeCalc(lengthInput: inScore)
            let desc = self.stringValue(v: shoesize, unit: "UK")
//                self.getDistanceStringBeween(pos1: currentPosition, pos2: start.position)
            DispatchQueue.main.async
                {
                    self.sizeLbl.text = desc
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor)
    {
        print("--> did add node")
        
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                
                // create plane with the "PlaneAnchor"
                let plane = Plane(anchor: planeAnchor)
                // add to the detected
                node.addChildNode(plane)
                // add to dictionary
                self.dictPlanes[planeAnchor] = plane
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor){    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)
    {
        DispatchQueue.main.async
            {
            if let planeAnchor = anchor as? ARPlaneAnchor
            {
                let plane = self.dictPlanes[planeAnchor]
                plane?.updateWith(planeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor)
    {
        if let planeAnchor = anchor as? ARPlaneAnchor {
        self.dictPlanes.removeValue(forKey: planeAnchor)
        }
    }
    
    func setUpARSession()
    {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
    }
    
    func nodeWithPosition(_ position: SCNVector3) -> SCNNode {
        // create sphere geometry with radius
        let sphere = SCNSphere(radius: 0.003)
        // set color
        sphere.firstMaterial?.diffuse.contents = UIColor(red: 255/255.0, green: 153/255.0, blue: 83/255.0, alpha: 1)
        // set lighting model
        sphere.firstMaterial?.lightingModel = .constant
        sphere.firstMaterial?.isDoubleSided = true
        // create node with 'sphere' geometry
        let node = SCNNode(geometry: sphere)
        node.position = position
        
        return node
    }

    @IBAction func plotPoint(_ sender: UIButton)
    {
        if let position = self.doHitTestOnExistingPlanes()
        {
            // add node at hit-position
            let node = self.nodeWithPosition(position)
            sceneView.scene.rootNode.addChildNode(node)
            
            // set start node
            startNode = node
        }
    }
    
}

