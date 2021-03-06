//
//  OddMenuItems.swift
//  Odd-iOS
//
//  Created by Patrick McConnell on 11/19/15.
//  Copyright © 2015 Odd Networks, LLC. All rights reserved.
//

import UIKit

enum OddMenuItemType : String {
  case Video = "video"
  case VideoCollection = "videoCollection"
  case Search = "search"
  case Home = "home"
  case MediaObjectCollection = "collection"
  case External = "external"
}

struct OddMenuItem {
  var title: String?
  var type: OddMenuItemType?
  var objectId: String?
  
  
  func tableViewCellReuseIdentifier() -> String {
    var reuseIdentifier: String
    switch type {
    case .Some(.Video):                 reuseIdentifier = "textLabelMenuCell"
    case .Some(.VideoCollection):       reuseIdentifier = "textLabelMenuCell"
    case .Some(.Search):                reuseIdentifier = "searchMenuCell"
    case .Some(.Home):                  reuseIdentifier = "textLabelMenuCell"
    case .Some(.MediaObjectCollection): reuseIdentifier = "textLabelMenuCell"
    case .Some(.External):              reuseIdentifier = "textLabelMenuCell"
    default:                            reuseIdentifier = "textLabelMenuCell"
    }
    
    return reuseIdentifier
  }
  
  mutating func menuItemFromJson(json: jsonObject) {
//   print("MENU OBJECT JSON \(json)")
    if let type = json["type"] as? String, id = json["id"] as? String, attributes = json["attributes"] as? jsonObject {
      self.objectId = id
      self.type = OddMenuItemType(rawValue: type)
      self.title = attributes["title"] as? String
    }
  }
}

struct OddMenuItemCollection {
  var title: String?
  var menuItems: Array<OddMenuItem>?
  
  static func buildCollectionForVideoCollection(videoCollections: Array<OddMediaObjectCollection>, collectionTitle: String) -> OddMenuItemCollection? {
    var newCollections = OddMenuItemCollection(title: collectionTitle, menuItems: [] )
    videoCollections.forEach({ (videoCollection) -> Void in
      if let title = videoCollection.title, id = videoCollection.id {
        let newMenuItem = OddMenuItem(title: title, type: .VideoCollection, objectId: id )
        newCollections.menuItems!.append(newMenuItem)
      }
    })
    
    if newCollections.menuItems!.isEmpty {
     return nil
    } else {
      return newCollections
    }
  }
}


struct OddMenu {
  var menuItemCollections = Array<OddMenuItemCollection>()
  
  func menuItemCollectionAtIndex(index: UInt) -> OddMenuItemCollection? {

    do {
      return try menuItemCollections.lookup(index)
    } catch {
      return nil
    }
  }
  
  func menuItemForIndexPath(indexPath: NSIndexPath) -> OddMenuItem? {
    let collectionIndex = indexPath.section
    let itemIndex = indexPath.row
    
    do {
      let menuItemCollection = try menuItemCollections.lookup( UInt(collectionIndex) )
      if let menuItems = menuItemCollection.menuItems {
        return try menuItems.lookup( UInt(itemIndex) )
      }
    } catch {
      print("Index Error on: menuItemForIndexPath Index = \(collectionIndex):\(itemIndex)" )
    }
    return nil
  }
}

