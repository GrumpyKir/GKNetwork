//
//  RemoteMappable.swift
//
//  Created by  Кирилл on 4/12/19.
//  Copyright © 2019 AppCraft. All rights reserved.
//

import Foundation

public protocol RemoteMappable {
    func mapResponseToDomain() -> AnyObject?
    func mapResponseFromDomain(data: AnyObject)
}

extension RemoteMappable {
    
    public func mapResponseToDomain() -> AnyObject {
        NSLog("[\(self)] - Error: Response to domain mapper not implemented")
        
        return self as AnyObject
    }
    
    public func mapResponseFromDomain(data: AnyObject) {
        NSLog("[\(self)] - Error: Domain to response mapper not implemented")
    }
    
}
