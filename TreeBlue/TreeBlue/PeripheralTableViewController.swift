//
//  PeripheralTableViewController.swift
//  TreeBlue
//
//  Created by wwwins on 2016/3/15.
//  Copyright © 2016年 wwwins. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate, CBPeripheralDelegate {

  @IBOutlet weak var tableView: UITableView!

  private var centralManager:CBCentralManager?
  private var discoveredPeripherals = Dictionary<String, PeripheralData>()
  private var tableDataSource:NSMutableArray = []

  override func viewDidLoad() {
    super.viewDidLoad()

    // 第一步: 設定 CBCentralManager
    // 第一個參數是指定 delegate
    // 第二個參數是 dispatch queue 設為 nil 則是使用 main queue
    centralManager = CBCentralManager(delegate: self, queue: nil)

  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)

    print("Stop scan")
    stopScanning()
    cleanup()
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
    // 不指定裝置，不允許抓取重覆的封包
    //centralManager?.scanForPeripheralsWithServices(nil, options: nil)
    // 不指定裝置，允許抓取重覆的封包，預設為不抓取(省電)
    centralManager?.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:NSNumber(bool: true)])
    // 指定裝置
    //centralManager?.scanForPeripheralsWithServices([hm10ServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey:NSNumber(bool: true)])

  }

  func stopScanning() {
    print("Stop scan")
    centralManager?.stopScan()

  }

  // 第四步: 儲存裝置資料
  func savePeripheral(discoverdPeripheral:CBPeripheral, rssi:NSNumber) {
    //print("save:\(discoverdPeripheral)")

    let peripheralData:PeripheralData = PeripheralData()
    peripheralData.name = discoverdPeripheral.name!
    peripheralData.uuidString = discoverdPeripheral.identifier.UUIDString
    peripheralData.rssi = rssi
    peripheralData.peripheral = discoverdPeripheral

    discoveredPeripherals.updateValue(peripheralData, forKey: peripheralData.uuidString)

    tableDataSource = NSMutableArray(array: Array(discoveredPeripherals.keys))

    dispatch_async(dispatch_get_main_queue(), {
      self.tableView.reloadData()
    })

  }

  func cleanup() {
    for (_,value) in discoveredPeripherals {
      let p = value
      if p.state == CBPeripheralState.Connected {
        centralManager?.cancelPeripheralConnection(p.peripheral!)
      }
    }
  }

  // 第三步: 發現裝置會觸發此函式
  func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
    if RSSI.integerValue > 0 {
      print("Device not at correct range:",RSSI)
      return
    }
    if let peripheralName = peripheral.name {
      for z in filterKeyWord {
        if (peripheralName.containsString(z)) {
          savePeripheral(peripheral, rssi: RSSI)
          break
        }
      }

    }
    //print("AdvertisementData:\(advertisementData)")

    // 第五步: 找出符合的裝置進行連線
    //centralManager?.connectPeripheral(peripheral, options: nil)

  }

  // 第六步: 連線成功會觸發此函式
  func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
    print("連線成功")

    // 連線成功後該裝置訊號就不會再觸發 didDiscoverPeripheral
    // 如果只有單一藍芽裝置，即可以停止掃描
    //stopScanning()

    // 第七步: 設定連線裝置 delegate
    // Make sure we get the discovery callbacks
    peripheral.delegate = self

    // 第八步: 掃描此連線裝置有哪些服務
    // Search only for services that match our UUID
    peripheral.discoverServices([hm10ServiceUUID])
    //peripheral.discoverServices(nil)

    // 第九步: 讀取 RSSI 值(非同步)
    peripheral.readRSSI()
  }

  func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
    print("結束連線")
    peripheral.delegate = nil

  }

  func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
    print("連線失敗")
  }

  // 第十步: 傳回連線裝置 RSSI 值
  func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
    // 更新
    savePeripheral(peripheral, rssi: RSSI)
  }

  // 第十一步: 發現裝置服務會觸發此函式
  func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
    if let err = error {
      print("Discover Services error:",err)
    }

    // 第十二步: 掃描 Characteristics
    print("p Services:",peripheral.services)
    for service in peripheral.services as [CBService]! {
      if (service.UUID == hm10ServiceUUID) {
        print("discover HM10")
        peripheral.discoverCharacteristics([hm10CharacteristicUUID], forService: service)
      }
    }

  }

  // 第十三步: 發現 Characteristics
  func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
    if let err = error {
      print("Discover Characteristics For Service error:",err)

    }

    // 比對 characteristics
    for characteristic in service.characteristics as [CBCharacteristic]! {
      if (characteristic.UUID == hm10CharacteristicUUID) {
        // 第十四步: 回應需要訂閱
        print("Set Notify")
        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
      }
    }

  }

  // 第十五步: 處理訂閱後傳回來的資料
  func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
    if let error = error {
      print("Error discovering services: \(error.localizedDescription)")
      return
    }

    print("characteristic:",characteristic)
    if let stringFromData = String(data: characteristic.value!, encoding: NSUTF8StringEncoding) {
      print("Received: \(stringFromData)")
      // 處理回傳資料
      // 取消訂閱
      //peripheral.setNotifyValue(false, forCharacteristic: characteristic)
      // 取消連線
      //centralManager?.cancelPeripheralConnection(peripheral)
    }
  }

  // 第十六步: 處理裝置訂閱狀態改變
  func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
    print("Error changing notification state: \(error?.localizedDescription)")

  }

  // 設定 tableViewCell 高度
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 88

  }

  func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return UITableViewAutomaticDimension
    
  }

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tableDataSource.count

  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("MyCellIdentifier", forIndexPath: indexPath)
    if let k = tableDataSource[indexPath.row] as? String {
      let p:PeripheralData = discoveredPeripherals[k]!
//      cell.textLabel?.text = String(format: "%@ [%.2f] [%@]", p.name, (p.rssi as! NSNumber).floatValue, p.state.description)
//      cell.detailTextLabel?.text = String(format:"%@", p.uuidString)
      (cell.viewWithTag(100) as! UILabel).text = String(format: "%@ [%.2f]", p.name, p.rssi.floatValue)
      if (p.state == CBPeripheralState.Disconnected) {
        (cell.viewWithTag(101) as! UILabel).textColor = UIColor.flatRedColorDark()
      }
      else {
        (cell.viewWithTag(101) as! UILabel).textColor = UIColor.flatBlueColor()
      }
      (cell.viewWithTag(101) as! UILabel).text = String(format: "%@", p.state.description)
      (cell.viewWithTag(102) as! UILabel).text = String(format: "%@", p.uuidString)
    }
    return cell
    
  }

  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if let k = tableDataSource[indexPath.row] as? String {
      let p:PeripheralData = discoveredPeripherals[k]!
      if (p.state == CBPeripheralState.Disconnected) {
        centralManager?.connectPeripheral(p.peripheral!, options: nil)
      }
      else {
        centralManager?.cancelPeripheralConnection(p.peripheral!)
      }

    }
  }
}
