//
//  BLEEnumExtension.swift
//  TreeBlue
//
//  Created by wwwins on 2016/3/8.
//  Copyright © 2016年 wwwins. All rights reserved.
//

import CoreBluetooth

extension CBCentralManagerState {
  var description:String {
    switch self {
    case .PoweredOff:
      return "CBCentralManagerStatePoweredOff"
    case .PoweredOn:
      return "CBCentralManagerStatePoweredOn"
    case .Resetting:
      return "CBCentralManagerStateResetting"
    case .Unauthorized:
      return "CBCentralManagerStateUnauthorized"
    case .Unknown:
      return "CBCentralManagerStateUnknown"
    case .Unsupported:
      return "CBCentralManagerStateUnsupported"
    }
  }
}

extension CBPeripheralState {
  var description:String {
    switch self {
    case .Connected:
      return "CBPeripheralStateConnected"
    case .Connecting:
      return "CBPeripheralStateConnecting"
    case .Disconnected:
      return "CBPeripheralStateDisconnected"
    case .Disconnecting:
      return "CBPeripheralStateDisconnecting"
    }
  }
}

extension CBPeripheralManagerState {
  var description:String {
    switch self {
    case .PoweredOff:
      return "CBPeripheralManagerStatePoweredOff"
    case .PoweredOn:
      return "CBPeripheralManagerStatePoweredOn"
    case .Resetting:
      return "CBPeripheralManagerStateResetting"
    case .Unauthorized:
      return "CBPeripheralManagerStateUnauthorized"
    case .Unknown:
      return "CBPeripheralManagerStateUnknown"
    case .Unsupported:
      return "CBPeripheralManagerStateUnsupported"
    }
  }
}
