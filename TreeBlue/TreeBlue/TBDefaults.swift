//
//  TBDefaults.swift
//  TreeBlue
//
//  Created by wwwins on 2016/3/8.
//  Copyright © 2016年 wwwins. All rights reserved.
//

import CoreBluetooth
import Foundation

let HM10_SERVICE_UUID = "FFE0"
let HM10_CHARACTERISTIC_UUID = "FFE1"

let hm10ServiceUUID = CBUUID(string: HM10_SERVICE_UUID)
let hm10CharacteristicUUID = CBUUID(string: HM10_CHARACTERISTIC_UUID)

let filterKeyWord:[String] = ["iPhone","HMSoft","abeacon"]
