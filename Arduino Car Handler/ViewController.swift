//
//  ViewController.swift
//  Arduino Car Handler
//
//  Created by Jerry Yan on 4/6/17.
//  Copyright © 2017 Jerry Yan. All rights reserved.
//

import Cocoa
import CoreGraphics



class ViewController: NSViewController, ORSSerialPortDelegate {

    // MARK: Class Variables
    
    /* Define the path of the serial port here */
    var arduino = ORSSerialPort(path: "/dev/cu.Bluetooth-Incoming-Port")
    var model:ADOModel = ADOModel()
    var lastData:JSON?
    var realTimeArray:[String] = []
    var stringInQueue = ""
    var keyIsDown = false
    
    var isRecording = false {
        didSet{
            if isRecording == false {
                lastData = nil
                print("Auto Recording has been stopped.")
            }else{
                print("Auto Recording has been started.")
            }
        }
    }
    
    // MARK: Serial Port Part
    
    func serialPortWasRemoved(fromSystem serialPort: ORSSerialPort) {
        statusLabel.stringValue = "Status: Disconnected"
        distanceLabel.stringValue = ""
    }
    
    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        statusLabel.stringValue = "Status: Connected"
        distanceLabel.stringValue = "Distance: N/A"
    }
    
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        statusLabel.stringValue = "Status: Disconnected"
        distanceLabel.stringValue = ""
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        statusLabel.stringValue = "Status: Disconnected"
        print(error)
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        
        func graphicHandler(_ currentData: JSON){
            guard isRecording else {
                return
            }
            guard let a_xf = Double(currentData["a_x"].stringValue), let a_yf = Double(currentData["a_y"].stringValue), let a_zf = Double(currentData["a_z"].stringValue), let usd = Double(currentData["USDistance"].stringValue) else {
                print("Current Data Failed")
                return
            }
            guard let a_xi = Double((lastData?["a_x"].stringValue) ?? ""), let a_yi = Double((lastData?["a_y"].stringValue) ?? ""), let a_zi = Double((lastData?["a_z"].stringValue) ?? "") else{
                print("Last Data Failed")
                lastData = currentData
                return
            }
            let d_ax = a_xf - a_xi
            let d_ay = a_yf - a_yi
            let d_az = a_zf - a_zi
            self.outputImageView.image = self.model.render(da: (d_ax, d_ay, d_az), distance: usd)
            lastData = currentData
        }
        
        func distanceHandler(_ currentData: JSON){
            guard let usd = currentData["USDistance"].string else {
                distanceLabel.stringValue = "Distance: N/A"
                return
            }
            distanceLabel.stringValue = "Distance: \(usd)cm"
        }
        
        let dataString = String(data: data, encoding: .utf8) ?? ""
        stringInQueue += dataString
        
        if stringInQueue.contains("\r\n"){
            let validString = stringInQueue.components(separatedBy: "\r\n")[0]
            let json = JSON(parseJSON: validString)
            graphicHandler(json)
            distanceHandler(json)
            print("\(validString)")
            stringInQueue = stringInQueue.components(separatedBy: "\r\n")[1]
        }
        
        //print(String(data: data, encoding: .utf8) ?? "[NULL]")
        
    }
    
    // MARK: Class Functions & Overriding Variables
    
    override func viewDidLoad() {
        super.viewDidLoad()
        outputImageView.imageScaling = .scaleProportionallyDown
        arduino?.delegate = self
        arduino?.baudRate = 9600
    }
    
    override func viewDidDisappear() {
        disconnect()
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        //print(event.keyCode)
        
        switch event.keyCode{
        case 0:
            outputImageView.image = model.cheatRender(.left)
        case 1:
            outputImageView.image = model.cheatRender(.backward)
        case 2:
            outputImageView.image = model.cheatRender(.right)
        case 13:
            outputImageView.image = model.cheatRender(.forward)
        default:
            break
        }
        
        guard keyIsDown == false else { return }
        
        switch event.keyCode{
        case 123:
            sendOrder(.left)
        case 126:
            sendOrder(.forward)
        case 124:
            sendOrder(.right)
        case 125:
            sendOrder(.backward)
        default:
            break
        }
        keyIsDown = true
        
    }
    
    override func keyUp(with event: NSEvent) {
        keyIsDown = false
        switch event.keyCode{
        case 123,124,125,126:
            sendOrder(.stop)
        default:
            break
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK: Arduino Functions
    
    func portSetup(_ sender: PortMenuItem){
        disconnect()
        if let items = sender.menu?.items, items.count > 0{
            for item in items {
                item.state = 0
            }
        }
        arduino = sender.orsPort
        arduino?.baudRate = 9600
        arduino?.delegate = self
        sender.state = 1
        
        print("\(arduino?.name ?? "") has been set up.")
    }
    
    enum arduinoOrder {
        case forward
        case backward
        case left
        case right
        case stop
    }
    
    func connect(){
        print("Attempted to connect.")
        arduino?.open()
    }
    
    func disconnect(){
        print("Attempted to disconnect.")
        arduino?.close()
    }
    
    func sendOrder(_ order: arduinoOrder){
        var sendingData = ""
        switch order {
        case .forward:
            sendingData = "e"
        case .left:
            sendingData = "d"
        case .stop:
            sendingData = "c"
        case .right:
            sendingData = "b"
        case .backward:
            sendingData = "a"
        }
        let data = Data(bytes: Array(sendingData.utf8))
        arduino?.send(data)
        print(order)
    }

    // MARK: IBOutlet Functions and Variables
    
    @IBOutlet weak var outputImageView: NSImageView!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var distanceLabel: NSTextField!
    @IBOutlet var inputTextView: NSTextView!
    @IBOutlet weak var tryButton: NSButton!
    @IBAction func resetAction(_ sender: Any) {
        outputImageView.image = nil
        inputTextView.string = ""
        model = ADOModel()
    }
    @IBAction func tryAction(_ sender: Any) {
        outputImageView.image = nil
        let text = inputTextView.string
        var textArray = text?.components(separatedBy: NSCharacterSet.newlines) ?? []
        textArray = textArray.filter({$0 != ""})
        
        self.model = ADOModel(dt: 5.0)
        
        guard textArray.count >= 2 else { return }
        for i in 1...(textArray.count - 1) {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (0.3 * Double(i)), execute: {
                let seti = textArray[i - 1]
                let setf = textArray[i]
                let datai = JSON(parseJSON: seti)
                let dataf = JSON(parseJSON: setf)
                let da_x = dataf["a_x"].doubleValue - datai["a_x"].doubleValue
                let da_y = dataf["a_y"].doubleValue - datai["a_y"].doubleValue
                let da_z = dataf["a_z"].doubleValue - datai["a_z"].doubleValue
                let usd = dataf["USDistance"].doubleValue
                
                self.outputImageView.image = self.model.render(da: (da_x, da_y, da_z), distance: usd)
            })
        }
    }
    /* Connect to the Serial Port, and disable the manual input */
    @IBAction func connectAction(_ sender: Any) {
        connect()
        inputTextView.isEditable = false
        tryButton.isEnabled = false
        inputTextView.resignFirstResponder()
    }
    /* Disconnect to the Serial Port, and re-enable the manual input */
    @IBAction func disconnectAction(_ sender: Any) {
        disconnect()
        inputTextView.isEditable = true
        tryButton.isEnabled = true
    }
    @IBAction func forwardAction(_ sender: Any) {
        sendOrder(.forward)
    }
    @IBAction func leftAction(_ sender: Any) {
        sendOrder(.left)
    }
    @IBAction func rightAction(_ sender: Any) {
        sendOrder(.right)
    }
    @IBAction func backwardAction(_ sender: Any) {
        sendOrder(.backward)
    }
    @IBAction func stopAction(_ sender: Any) {
        sendOrder(.stop)
    }
    /* Start/Continue Auto Recording */
    @IBAction func startAutoRecordingAction(_ sender: Any) {
        isRecording = true
    }
    /* Pause Auto Recording, with image and data perserved */
    @IBAction func pauseAutoRecordingAction(_ sender: Any) {
        isRecording = false
    }
    /* Pause Auto Recording, with image perserved, data cleared */
    @IBAction func stopAutoRecordingAction(_ sender: Any) {
        isRecording = false
        model = ADOModel()
    }
}

class IndexView: NSView{
    override var acceptsFirstResponder: Bool {
        return true
    }
    override func keyDown(with event: NSEvent) {
        self.nextResponder?.keyDown(with: event)
    }
    
    override func keyUp(with event: NSEvent) {
        self.nextResponder?.keyUp(with: event)
    }
}

class IndexWindow: NSWindow{
    override var acceptsFirstResponder: Bool {
        return true
    }
    override func keyDown(with event: NSEvent) {
        self.nextResponder?.keyDown(with: event)
    }
    
    override func keyUp(with event: NSEvent) {
        self.nextResponder?.keyUp(with: event)
    }
}

class IndexWindowController: NSWindowController{
    override var acceptsFirstResponder: Bool {
        return true
    }
    override func keyDown(with event: NSEvent) {
        self.nextResponder?.keyDown(with: event)
    }
    
    override func keyUp(with event: NSEvent) {
        self.nextResponder?.keyUp(with: event)
    }
}

class ADOModel{
    init(){
    }
    /* Initialize with the time interval (in ms, default as 10.0) */
    convenience init(dt:Double){
        self.init()
        self.dt = dt
    }
    var v_x = 0.0
    var v_y = 0.0
    var a_x = 0.0
    var a_y = 0.0
    var da_x = 0.0
    var da_y = 0.0
    var x = 0.0
    var y = 0.0
    var a_z = 10.04
    var da_z = 0.0
    var dt = 1.0
    var point:NSPoint{
        return NSPoint(x:x, y:y)
    }
    var usd = 0.0
    var usdLimit:Double = Double.infinity /* Define the Minimum Ultrasonic Distance here (in cm, default as no limit) */
    
    var max = (100.0, 100.0)
    var min = (0.0, 0.0)
    
    var rawPointSet:[(NSPoint, Double)] = []
    var translatedPointSet:[(NSPoint, Double)] {
        var pointSet:[(NSPoint, Double)] = []
        guard rawPointSet.count != 0 else { return [] }
        for i in 0...(rawPointSet.count - 1){
            pointSet.append((NSPoint(x: rawPointSet[i].0.x - CGFloat(min.0), y: rawPointSet[i].0.y - CGFloat(min.1)), rawPointSet[i].1))
        }
        return pointSet
    }
    
    /* Render the path of previous points, with the input of the da_x, da_y and usd */
    func render(da: (Double, Double, Double), distance:Double? = nil) -> NSImage {
        self.da_x = da.0
        self.da_y = da.1
        self.da_z = da.2
        
        if let usd = distance {
            self.usd = usd
        }
        
        if abs(da.0) >= 0.2 && abs(da.1) >= 0.2 && abs(da.2) >= 0.2  {
            a_z = a_z + (da_z * dt)
            
            a_x = a_x + (((da_x * a_z) + (a_x * da_z)) / 10.04 * dt)
            v_x = v_x + (a_x * dt)
            x = x + (v_x * dt)
            a_y = a_y + (((da_y * a_z) + (a_y * da_z)) / 10.04 * dt)
            v_y = v_y + (a_y * dt)
            y = y + (v_y * dt)
            
            let max_speed = 15.0
            
            if v_x >= max_speed {
                v_x = max_speed
            }
            
            if v_y >= max_speed {
                v_y = max_speed
            }
            
            print(">> a_x: \(a_x) v_x: \(v_x) a_y: \(a_y) v_y: \(v_y)")
            
            rawPointSet.append((point, self.usd))
            
            maxNminCheck()
            
        }else{
            print(">> This point was filtered.")
            v_x = 0
            a_x = 0
            v_y = 0
            a_y = 0
            a_z = 10.04
        }
        
        return generateImage()
    }
    
    enum cheatOrder{
        case forward
        case right
        case backward
        case left
        case stop
    }
    
    func cheatRender(_ order: cheatOrder) -> NSImage{
        v_x = 0
        a_x = 0
        v_y = 0
        a_y = 0
        a_z = 10.04
        
        let distance = 20.0
        switch order{
        case .forward:
            y = y + distance
        case .backward:
            y = y - distance
        case .right:
            x = x + distance
        case .left:
            x = x - distance
        case .stop:
            break
        }
        
        maxNminCheck()
        rawPointSet.append((point, self.usd))
        
        return generateImage()
    }
    
    private func generateImage() -> NSImage {
        guard translatedPointSet.count != 0 else { return NSImage() }
        let size = NSSize(width:(max.0 - min.0), height:(max.1 - min.1))
        let image = NSImage(size: size)
        let path = NSBezierPath()
        path.move(to: translatedPointSet[0].0)
        path.lineWidth = 4.0
        image.lockFocus()
        for i in 0...(translatedPointSet.count - 1){
        /* Not drawing the line to the points where usd is larger than the limit */
        if(translatedPointSet[i].1 <= usdLimit){
        path.line(to: translatedPointSet[i].0)
        }
        }
        path.stroke()
        image.unlockFocus()
        return image
    }
    
    /* Not affecting max and min if usd is larger than the limit */
    private func maxNminCheck(){
        if usd <= usdLimit{
            if x > max.0 {
                max.0 = x
            }
            if x < min.0 {
                min.0 = x
            }
            if y > max.1 {
                max.1 = y
            }
            if y < min.1 {
                min.1 = y
            }
        }
    }
    
    func reset(){
        v_x = 0.0
        v_y = 0.0
        a_x = 0.0
        a_y = 0.0
        da_x = 0.0
        da_y = 0.0
        x = 0.0
        y = 0.0
        a_z = 10.04
        da_z = 0.0
        dt = 1.0
        usd = 0.0
        usdLimit = Double.infinity /* Define the Minimum Ultrasonic Distance here (in cm, default as no limit) */
        max = (100.0, 100.0)
        min = (0.0, 0.0)
        rawPointSet.removeAll()
    }
}

