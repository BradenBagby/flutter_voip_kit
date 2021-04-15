//
//  Call.swift
//  flutter_voip_kit
//
//  Created by Braden Bagby on 4/15/21.
//

import Foundation


class Call : Codable{
    let uuid : UUID
    let handle : String
    
    init(uuid : UUID, handle : String, outgoing : Bool) {
        self.uuid = uuid
        self.handle = handle
    }
    
    
    
 
}
