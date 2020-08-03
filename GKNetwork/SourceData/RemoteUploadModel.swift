//
//  RemoteUploadModel.swift
//
//  Created by  Кирилл on 4/12/19.
//  Copyright © 2019 AppCraft. All rights reserved.
//

import UIKit

public struct RemoteUploadModel {
    public var filename: String
    public var data: Data
    
    public init(filename: String, data: Data) {
        self.filename = filename
        self.data = data
    }
}
