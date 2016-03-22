//
//  PeripheralData.swift
//  TreeBlue
//
//  Created by wwwins on 2016/3/22.
//  Copyright © 2016年 wwwins. All rights reserved.
//

import Foundation
import CoreBluetooth

class PeripheralData {
  var name:String = ""
  var uuidString:String = ""
  var discoveredrssi:NSNumber = 0.0
  var rssi:NSNumber {
    get {
      if (self.state == CBPeripheralState.Connected) {
        peripheral?.readRSSI()
      }
      return discoveredrssi
    }
    set (newValue) {
      self.discoveredrssi = newValue
    }
  }
  var state:CBPeripheralState {
    get {
      if (peripheral == nil) {
        return CBPeripheralState.Disconnected
      }
      else {
        return peripheral!.state
      }
    }
  }
  var peripheral:CBPeripheral?

}

