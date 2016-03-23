# Core Bluetooth Practices
## Central 手機端流程
### 設定 CentralManager
```swift
centralManager = CBCentralManager(delegate: self, queue: nil)
```
###  當設定 CBCentralManagerDelegate 最少需要實作這個函式
```swift
func centralManagerDidUpdateState(central: CBCentralManager)
```
### 掃描裝置(可指定或不指定特定裝置)
```swift
// 不指定裝置，不允許抓取重覆的封包
centralManager?.scanForPeripheralsWithServices(nil, options: nil)
// 不指定裝置，允許抓取重覆的封包，預設為不抓取(省電)
centralManager?.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:NSNumber(bool: true)])
// 指定裝置
centralManager?.scanForPeripheralsWithServices([hm10ServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey:NSNumber(bool: true)])
```
### 發現裝置會觸發此函式
```swift
func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber)
```
### 找出符合的裝置進行連線
```swift
centralManager?.connectPeripheral(peripheral, options: nil)
```
### 連線成功會觸發此函式
```swift
func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral)
```
### 設定連線裝置 delegate
```swift
peripheral.delegate
```
### 連線成功後可讀取 RSSI 值(非同步)，已成功連線的裝置不會出現在 didDiscoverPeripheral
```swift
peripheral.readRSSI()
```
### 傳回該裝置 RSSI 值
```swift
func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?)
```
### 掃描此連線裝置有提供哪些服務(可指定只檢查特定服務)
```swift
peripheral.discoverServices([hm10ServiceUUID])
```
### 當發現該連線裝置有此服務會觸發此函式
```swift
func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?)
```
### 掃描特定 Characteristics
```swift
peripheral.discoverCharacteristics([hm10CharacteristicUUID], forService: service)
```
### 發現特定 Characteristics
```swift
func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?)
```
### 訂閱/取消訂閱 Characteristics
```swift
peripheral.setNotifyValue(true, forCharacteristic: characteristic)
```
### 處理訂閱後傳回來的資料
```swift
func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?)
```
### 裝置訂閱狀態改變時會觸發
```swift
func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?)
```

## Peripheral HM-10
### 直接對 SoftwareSerial 讀寫
