//
//  ViewController.swift
//  TreeBlue
//
//  Created by wwwins on 2016/3/8.
//  Copyright © 2016年 wwwins. All rights reserved.
//

import UIKit
import CoreBluetooth
import ChameleonFramework

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

  @IBOutlet weak var buttonForCharacter: UIButton!
  @IBOutlet weak var layoutConstraintForBottom: NSLayoutConstraint!
  private var layoutConstraintForBottomConstant:CGFloat = 0.0

  private var centralManager:CBCentralManager?
  private var connectedPeripheral:CBPeripheral?
  private var discoveredPeripheral:CBPeripheral?

  private var dots:NSMutableDictionary?
  private var arrPositionX:[UInt] = [UInt]()
  private var dictRSSI = Dictionary<String, NSMutableArray>()

  private weak var timer:NSTimer?

  private var radarLine:CALayer?

  override func viewDidLoad() {
    super.viewDidLoad()

    // 第一步: 設定 CBCentralManager
    // 第一個參數是指定 delegate
    // 第二個參數是 dispatch queue 設為 nil 則是使用 main queue
    centralManager = CBCentralManager(delegate: self, queue: nil)

    dots = NSMutableDictionary()

    var d:Int = -1
    var calX:Int = Int(self.view.frame.size.width * 0.5)
    for i in 0...12 {
      d = d * -1
      calX = calX + i*30*d
      if calX < 0 {
        break
      }
      arrPositionX.append(UInt(calX))

    }


  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    createRadar()

  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

    startRadar()

    updateCharacterConstraintForBottom()
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)

    if connectedPeripheral?.state == CBPeripheralState.Connected {
      centralManager?.cancelPeripheralConnection(connectedPeripheral!)
    }

    print("Stop scan")
    stopScanning()
    stopRadar()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.

  }

  // 當設定 CBCentralManagerDelegate 最少需要實作這個函式
  func centralManagerDidUpdateState(central: CBCentralManager) {
    print("central state:\(central.state.description)")
    if central.state != CBCentralManagerState.PoweredOn {
      return;
    }
    print("Start scan")
    startScanning()

  }

  // 第二步: 掃描裝置(可指定或不指定特定裝置)
  func startScanning() {
    // 不然定裝置，不允許抓取重覆的封包
    //centralManager?.scanForPeripheralsWithServices(nil, options: nil)
    // 不指定裝置，允許抓取重覆的封包，預設為不抓取(省電)
    centralManager?.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:NSNumber(bool: true)])
    // 指定裝置
    //centralManager?.scanForPeripheralsWithServices([hm10ServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey:NSNumber(bool: true)])
    timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("onTimer"), userInfo: nil, repeats: true)

  }

  func stopScanning() {
    centralManager?.stopScan()
    timer?.invalidate()

  }

  func onTimer() {
    print("onTimer")
    for (key,value) in dictRSSI {
      if (value.count > 3) {
        let maxValue = value.valueForKeyPath("@max.self")
        value.removeObjectAtIndex(value.indexOfObject(maxValue!))
        let minValue = value.valueForKeyPath("@min.self")
        value.removeObjectAtIndex(value.indexOfObject(minValue!))
        let avgRSSI:NSNumber = NSNumber(double: value.valueForKeyPath("@avg.self") as! Double)
        print ("avg:",key,avgRSSI)
        dictRSSI[key]!.removeAllObjects()
        updateDots(key, RSSI:avgRSSI)
      }
    }
    //dictRSSI = Dictionary<String, NSMutableArray>()
    
    // 讀取已連線裝置 RSSI 值
    connectedPeripheral?.readRSSI()
  }

  func saveRSSI(name:String, RSSI:NSNumber) {
    if ((dictRSSI.indexForKey(name)) == nil) {
      dictRSSI[name] = NSMutableArray()
    }
    dictRSSI[name]?.addObject(RSSI)
  }

  // 第三步: 發現裝置會觸發此函式
  func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {

    // Reject if the signal strength is too low to be close enough (Close is around -22dB)
    // 擋掉不合理的訊號
    //if  RSSI.integerValue < -15 && RSSI.integerValue > -35 {
    //  print("Device not at correct range")
    //  return
    //}

    if RSSI.integerValue > 0 {
      print("Device not at correct range:",RSSI)
      return
    }

    if let peripheralName = peripheral.name {
      for z in filterKeyWord {
        if (peripheralName.containsString(z)) {
          saveRSSI(peripheral.identifier.UUIDString, RSSI: RSSI)
          break
        }
      }

    }
    //print("AdvertisementData:\(advertisementData)")

    // 找出符合的裝置進行連線
    if (peripheral.identifier.UUIDString == DEVICE_IDENTIFIER_UUID) {
      if (discoveredPeripheral != peripheral) {
        print("Start connect peripheral")
        discoveredPeripheral = peripheral
        centralManager?.connectPeripheral(peripheral, options: nil)
      }
    }
  }

  /**
  第四步: 連線成功會觸發此函式

  - parameter central:    central description
  - parameter peripheral: peripheral description
  */
  func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
    print("didConnectPeripheral")
    if (connectedPeripheral == peripheral) {
      return
    }

    connectedPeripheral = peripheral
    peripheral.delegate = self
    peripheral.readRSSI()
    
  }

  func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
    connectedPeripheral = nil
    discoveredPeripheral = nil

  }

  func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
    connectedPeripheral = nil
    discoveredPeripheral = nil
  }

  // 傳回連線裝置 RSSI 值
  func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
    saveRSSI(peripheral.identifier.UUIDString, RSSI: RSSI)

  }

  /**
  依據 RSSI 計算距離(http://stackoverflow.com/questions/20416218/understanding-ibeacon-distancing/20434019#20434019)

  - parameter rssi:    rssi description
  - parameter txPower: txPower description

  - returns: 距離(單位:m)，0 為超出合理距離
  */
  func calculateDistance(rssi: NSNumber, txPower: NSNumber = -59.0) -> NSNumber {
    let rssi = rssi.doubleValue
    if rssi >= 0 {
      return 0.0
    }
    let ratio:double_t = rssi * 1.0 / txPower.doubleValue
    if ratio < 1.0 {
      return pow(ratio, 10.0)
    }
    else {
      return (0.89976) * pow(ratio, 7.7095) + 0.111
    }

  }

  func createDot(size:CGSize, point:CGPoint, color:UIColor) -> CALayer {
    let plane:CALayer = CALayer()
    plane.backgroundColor = color.CGColor
    plane.frame = CGRectMake(0, 0, size.width, size.height)
    plane.position = point
    plane.anchorPoint = CGPointMake(0.5, 0.5)
    plane.borderWidth = 0.0
    plane.cornerRadius = size.width*0.5
    return plane
  }

  func updateDots(name:String!, RSSI:NSNumber) {
    // 從 RSSI 值取得距離
    let distfloat = CGFloat(calculateDistance(RSSI).floatValue)
    let distance = String(format:"%.2f", distfloat)
    if distfloat == 0 {
      return
    }
    // 圖形化
    if let peripheralName = name {
      print("Discover Peripheral:\(peripheralName) RSSI:\(RSSI) Distance:\(distance)m")
      if (dots!.objectForKey(peripheralName) != nil) {
        let dot:CALayer = dots!.objectForKey(peripheralName) as! CALayer
        var p:CGPoint = dot.position;
        if (distfloat>10) {
          dot.backgroundColor = UIColor.flatRedColor().CGColor
        }
        else {
          dot.backgroundColor = UIColor.flatGreenColor().CGColor
          if (name == DEVICE_IDENTIFIER_UUID) {
            dot.backgroundColor = UIColor.flatSkyBlueColor().CGColor
          }
        }
        p.y = self.view.frame.size.height - self.view.frame.size.height*(distfloat/15) - 60.0
        if (p.y < 0) {
          p.y = 100
        }
        dot.position = p;

      }
      else {
        let rx = arrPositionX.removeFirst()
        //let rx = arc4random_uniform(UInt32(self.view.frame.size.width) - 20) + 10
        let ry = arc4random_uniform(UInt32(self.view.frame.size.height) - 20) + 10
        let dot:CALayer = createDot(CGSizeMake(20, 20), point: CGPointMake(CGFloat(rx), CGFloat(ry)), color: UIColor.flatGreenColor())
        dots?.setObject(dot, forKey: peripheralName)
        self.view.layer.addSublayer(dot)
      }

    }
    else {
      print("Discover Peripheral:nil RSSI:\(RSSI) Distance:\(distance)m")
    }

  }

  /**
  畫線

  - parameter pointFrom: 起點
  - parameter pointTo:   終點
  - parameter color:     顏色

  - returns: <#return value description#>
  */
  func createLine(pointFrom:CGPoint, pointTo:CGPoint, color:UIColor) -> CALayer {
    let line:CAShapeLayer = CAShapeLayer()
    let path:UIBezierPath = UIBezierPath()
    path.moveToPoint(pointFrom)
    path.addLineToPoint(pointTo)
    line.path = path.CGPath
    line.lineWidth = 2.0
    line.strokeColor = color.CGColor

    return line
    
  }

  func startRadar() {
    radarLine = createLine(CGPointMake(0, 0), pointTo: CGPointMake(1000, 0), color: UIColor.flatGreenColorDark())
    radarLine!.position = CGPointMake(self.view.frame.width*0.5, self.view.frame.height+2)

    let pathAnimation = CABasicAnimation()
    pathAnimation.duration = 5.0
    //pathAnimation.fromValue = M_PI
    pathAnimation.toValue = 2*M_PI
    pathAnimation.repeatCount = 9999
    radarLine!.addAnimation(pathAnimation, forKey: "transform.rotation")

    self.view.layer.addSublayer(radarLine!)
  }

  func stopRadar() {
    radarLine?.removeAllAnimations()
    radarLine?.removeFromSuperlayer()

  }

  func createRadar() {
    let halfWidth = self.view.frame.size.width*0.5
    let halfHeight = self.view.frame.size.height*0.5
    let myGradientLayer = createGradientLayer()
    myGradientLayer.position = CGPointMake(halfWidth,halfHeight)
    self.view.layer.insertSublayer(myGradientLayer, atIndex: 0)

    for i in 0...4 {
      let circleLayer:CAShapeLayer = createCircle(CGSizeMake(CGFloat(200+300*i), CGFloat(200+300*i)))
      circleLayer.position = CGPointMake(halfWidth, halfHeight*2)
      self.view.layer.addSublayer(circleLayer)
    }

  }

  func updateCharacterConstraintForBottom() {
    self.layoutConstraintForBottom.constant = 0.0
//    UIView.animateWithDuration(0.5) { () -> Void in
//      self.view.layoutIfNeeded()
//    }
    UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.75, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
      self.view.layoutIfNeeded()
      }, completion: nil)
  }

  func createGradientLayer() -> CAGradientLayer {
    let gradientLayer:CAGradientLayer = CAGradientLayer()
    gradientLayer.bounds = self.view.bounds
    //gradientLayer.colors = [Colors.black.CGColor, Colors.green.CGColor, Colors.lightGreen.CGColor]
    //gradientLayer.locations = [0,0.4,1]
    gradientLayer.colors = [Colors.black.CGColor, Colors.green.CGColor]
    gradientLayer.locations = [0,1]
    gradientLayer.startPoint = CGPointMake(0, 0)
    gradientLayer.endPoint = CGPointMake(0, 1)

    return gradientLayer
  }

  func createCircle(size:CGSize) -> CAShapeLayer {
    let circleLayer:CAShapeLayer = CAShapeLayer()
    circleLayer.bounds = CGRectMake(0, 0, size.width, size.height)
    circleLayer.fillColor = UIColor.clearColor().CGColor
    circleLayer.strokeColor = UIColor.greenColor().CGColor
    circleLayer.lineWidth = 3.0
    circleLayer.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)).CGPath
    return circleLayer
  }

}

