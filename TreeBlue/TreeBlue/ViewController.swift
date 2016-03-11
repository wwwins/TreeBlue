//
//  ViewController.swift
//  TreeBlue
//
//  Created by wwwins on 2016/3/8.
//  Copyright © 2016年 wwwins. All rights reserved.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController, CBCentralManagerDelegate {

  //private let filterKeyWord:String = "HMSoft"
  private let filterKeyWord:String = "abeacon"

  private var centralManager:CBCentralManager?
  private var dots:NSMutableDictionary?
  private var arrPositionX:[UInt] = [UInt]()
  private var dictRSSI = Dictionary<String, NSMutableArray>()

  private weak var timer:NSTimer?

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

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)

    print("Stop scan")
    stopScanning()

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
      if (value.count > 5) {
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
      if (peripheralName.containsString(filterKeyWord)) {
        saveRSSI(peripheral.name!, RSSI: RSSI)
      }
    }
    //print("AdvertisementData:\(advertisementData)")

    // 找出符合的裝置進行連線
    //centralManager?.connectPeripheral(peripheral, options: nil)
  }

  /**
  第四步: 連線成功會觸發此函式

  - parameter central:    central description
  - parameter peripheral: peripheral description
  */
  func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
    print("didConnectPeripheral")
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
        if (distfloat>5) {
          dot.backgroundColor = UIColor.redColor().CGColor
        }
        else {
          dot.backgroundColor = UIColor.greenColor().CGColor
        }
        p.y = self.view.frame.size.height - self.view.frame.size.height*(distfloat/15) - 10.0
        if (p.y < 0) {
          p.y = 100
        }
        dot.position = p;

      }
      else {
        let rx = arrPositionX.removeFirst()
        //let rx = arc4random_uniform(UInt32(self.view.frame.size.width) - 20) + 10
        let ry = arc4random_uniform(UInt32(self.view.frame.size.height) - 20) + 10
        let dot:CALayer = createDot(CGSizeMake(20, 20), point: CGPointMake(CGFloat(rx), CGFloat(ry)), color: UIColor.greenColor())
        dots?.setObject(dot, forKey: peripheralName)
        self.view.layer.addSublayer(dot)
      }

    }
    else {
      print("Discover Peripheral:nil RSSI:\(RSSI) Distance:\(distance)m")
    }

  }

}

