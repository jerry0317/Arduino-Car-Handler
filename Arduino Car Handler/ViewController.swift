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
    let arduino = ORSSerialPort(path: "/dev/tty.Bluetooth-Incoming-Port")
    var model:ADOModel = ADOModel(dt: 10.0)
    var lastData:JSON?
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
        return
    }
    
    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        statusLabel.stringValue = "Status: Connected"
    }
    
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        statusLabel.stringValue = "Status: Disconnected"
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        statusLabel.stringValue = "Status: Disconnected"
        print(error)
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        print(String(data: data, encoding: .utf8) ?? "[NULL]")
        guard isRecording else {
            return
        }
        let currentData = JSON(data: data)
        guard let a_xf = currentData["a_x"].double, let a_yf = currentData["a_y"].double, let usd = currentData["USDistance"].double else {
            return
        }
        guard let a_xi = lastData?["a_x"].double, let a_yi = lastData?["a_y"].double else{
            lastData = currentData
            return
        }
        let d_ax = a_xf - a_xi
        let d_ay = a_yf - a_yi
        self.outputImageView.image = self.model.render(da: (d_ax, d_ay), distance: usd)
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
        
    }
    
    override func keyUp(with event: NSEvent) {
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
            sendingData = "a"
        case .left:
            sendingData = "b"
        case .stop:
            sendingData = "c"
        case .right:
            sendingData = "d"
        case .backward:
            sendingData = "e"
        }
        let data = Data(bytes: Array(sendingData.utf8))
        arduino?.send(data)
        print(order)
    }

    // MARK: IBOutlet Functions and Variables
    
    @IBOutlet weak var outputImageView: NSImageView!
    @IBOutlet weak var statusLabel: NSTextField!

    @IBOutlet var inputTextView: NSTextView!
    @IBOutlet weak var tryButton: NSButton!
    @IBAction func resetAction(_ sender: Any) {
        outputImageView.image = nil
        inputTextView.string = nil
        model = ADOModel(dt: 10.0)
    }
    @IBAction func tryAction(_ sender: Any) {
        outputImageView.image = nil
        let text = inputTextView.string
        var textArray = text?.components(separatedBy: NSCharacterSet.newlines) ?? []
        textArray = textArray.filter({$0 != ""})
        
        self.model = ADOModel(dt: 10.0)
        
        guard textArray.count >= 2 else { return }
        for i in 1...(textArray.count - 1) {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (0.3 * Double(i)), execute: {
                let seti = textArray[i - 1]
                let setf = textArray[i]
                let datai = JSON(parseJSON: seti)
                let dataf = JSON(parseJSON: setf)
                let da_x = dataf["a_x"].doubleValue - datai["a_x"].doubleValue
                let da_y = dataf["a_y"].doubleValue - datai["a_y"].doubleValue
                let usd = dataf["USDistance"].doubleValue
                
                self.outputImageView.image = self.model.render(da: (da_x, da_y), distance: usd)
            })
        }
    }
    /* Connect to the Serial Port, and disable the manual input */
    @IBAction func connectAction(_ sender: Any) {
        connect()
        inputTextView.isEditable = false
        tryButton.isEnabled = false
        self.view.becomeFirstResponder()
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
        model = ADOModel(dt: 10.0)
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
    var dt = 10.0
    var point:NSPoint{
        return NSPoint(x:x, y:y)
    }
    var usd = 0.0
    let usdLimit:Double = Double.infinity /* Define the Minimum Ultrasonic Distance here (in cm, default as no limit) */
    
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
    func render(da: (Double, Double), distance:Double? = nil) -> NSImage {
        self.da_x = da.0
        self.da_y = da.1
        a_x = a_x + (da_x * dt)
        v_x = v_x + (a_x * dt)
        x = x + (v_x * dt)
        a_y = a_y + (da_y * dt)
        v_y = v_y + (a_y * dt)
        y = y + (v_y * dt)
        
        
        if let usd = distance {
            self.usd = usd
        }
        rawPointSet.append((point, self.usd))
        
        /* Not affecting max and min if usd is smaller than the limit */
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
        
        guard translatedPointSet.count != 0 else { return NSImage() }
        let size = NSSize(width:(max.0 - min.0), height:(max.1 - min.1))
        let image = NSImage(size: size)
        let path = NSBezierPath()
        path.move(to: translatedPointSet[0].0)
        image.lockFocus()
        for i in 0...(translatedPointSet.count - 1){
            /* Not drawing the line to the points where usd is smaller than the limit */
            if(translatedPointSet[i].1 <= usdLimit){
                path.line(to: translatedPointSet[i].0)
            }
        }
        path.stroke()
        image.unlockFocus()
        return image
    }
}

