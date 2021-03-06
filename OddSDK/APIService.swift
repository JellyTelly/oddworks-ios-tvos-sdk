//
//
//  APIService.swift
//
//  Created by Patrick McConnell on 7/31/15.
//  Copyright (c) 2015 Odd Networks, LLC. All rights reserved.
//

import UIKit

/// A helper object to provide either an object
/// or the error returned from the server
public typealias APICallback = ((AnyObject?, NSError?) -> Void)

/// The APIService can be configured to use either the
/// Staging or Production servers using this enum type.
///
/// See also: `serverMode`
@objc public enum OddServerMode: Int {
  case Staging
  case Production
  case Beta
  case Local
}


/// A Struct to encapsulate various device information fields
///
/// No configuration of the Struct is required. All required information is
/// included by calling `constructHeader()`
struct UserAgentHeader {
  let deviceModel = UIDevice.currentDevice().model.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
  let deviceName = UIDevice.currentDevice().name.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
  let buildVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String
  let osVersion = UIDevice.currentDevice().systemVersion.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
  let os = UIDevice.currentDevice().systemName.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
  
  /// A helper method for `UserAgentHeader` to build the correct device information fields required
  /// to be provided with each request to the API server
  ///
  /// No parameters are required. All required information is automatically built and returned in the response.
  ///
  /// returns: A `string` containing the required device information
  func constructHeader() -> String {
    if let build = buildVersion, encodedBuild = build.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet()), deviceModel = deviceModel, deviceName = deviceName, os = os, osVersion = osVersion {
      let userAgentHeader = "platform[name]=\("Apple")&model[name]=\(deviceModel)&model[version]=\(deviceName)&os[name]=\(os)&os[version]=\(osVersion)&buildVersion=\(encodedBuild)"
      return userAgentHeader
    } else {
      return "platform[name]=\("Apple")&model[name]=\("unknown")&model[version]=\("unknown")&os[name]=\("unknown")&os[version]=\("unknown")&buildVersion=\("unknown")"
    }
  }
}


/// Handles http requests for the API server.
/// Parses reponses or errors returning the appropriate
/// `JSON` or server error information
public class APIService: NSObject {

  /// Only one instance of this class is required for any app.
  /// Access should be made through this singleton
  static let sharedService = APIService()
  
  /// Determines whether to access the Staging or Production Server
  /// 
  /// Defaults to Production
  ///
  /// Valid options are .Production (the default), .Staging & .Beta
  /// 
  /// Do not use .Beta unless directed to be Oddworks. Customer data
  /// is not normally synched to the beta server
  #if BETA
    /// Determines whether to access the Staging or Production Server
    ///
    /// The BETA SDK Defaults to Beta
    ///
    /// Valid options are .Production (the default), .Staging & .Beta
    ///
    public var serverMode: OddServerMode = .Beta
  #else
    // Determines whether to access the Staging or Production Server
    //
    // Release versions of the SDK Default to Production
    //
    // Valid options are .Production (the default), .Staging & .Beta
    //
    public var serverMode: OddServerMode = .Production
  #endif
  
  /// The address of the API server to be used by the `APIService`
  ///
  /// This is combined with a version string to determine the API view format provided to 
  /// client applications
  /// 
  /// This value is read only and configured by setting `serverMode`
  /// 
  /// Currently, unless `.Staging` is set for `serverMode` it will hit the production server
  ///
  var baseURL: String {
    get {
      switch serverMode {
      case .Staging: return "https://device-staging.oddworks.io"
      case .Beta: return "https://beta.oddworks.io"
      case .Local: return "http://127.0.0.1:8000"
      default: return "https://device.oddworks.io"
      }
    }
  }
  
  /// The device/organization specific authorization token as provided by Odd
  /// must be set before the API can be accessed successfully.
  public var authToken: String = ""

  private var userAuthToken: String {
    get {
      let defaults = NSUserDefaults.standardUserDefaults()
      guard let token = defaults.stringForKey("OddUserAuthToken") else {
        return authToken
      }
      return token
    }
  }

  /// The url sting used by the APIService to contact the API server
  /// 
  /// This string is a combination of the `baseURL` and the currently supported 
  /// API version
  var apiURL: String { return "\(baseURL)/" }
  
  /// A `String` built from various device infomation fields to be sent to the API server 
  /// with each request
  var agentHeader = UserAgentHeader()
  
  
  //MARK: INITIALIZERS
  
  /// Designated initializer
  ///
  /// No configurable options at this time
  override init() {
    super.init()
  }
    
  //MARK: Requests
  
  /// Performs a `GET` request on the API Server
  ///
  /// - parameter params: an optional `Dictionary` containing any parameters required for the request
  /// - parameter url: a `String` containing the route for the API method to be requested
  /// - parameter callbck: an `APICallback` that will either contain the json of the 
  /// requested object or an error if the request failed
  ///
  /// See also: `APICallback`
  public func get(params: [ String : String ]?, url: String, callback: APICallback) {
    request("GET", params: params, url: url, callback: callback)
  }
  
  /// Performs a `POST` request on the API Server
  ///
  /// - parameter params: an optional `Dictionary` containing any parameters required for the request
  /// - parameter url: a `String` containing the route for the API method to be requested
  /// - parameter callbck: an `APICallback` that will either contain the json of the
  /// requested object or an error if the request failed
  ///
  /// See also: `APICallback`
  public func post(params: [ String : AnyObject ]?, url: String, callback: APICallback) {
    request("POST", params: params, url: url, callback: callback)
  }
  
  /// Performs a `PUT` request on the API Server
  ///
  /// - parameter params: an optional `Dictionary` containing any parameters required for the request
  /// - parameter url: a `String` containing the route for the API method to be requested
  /// - parameter callbck: an `APICallback` that will either contain the json of the
  /// requested object or an error if the request failed
  ///
  /// See also: `APICallback`
  public func put(params: [ String : String ]?, url: String, callback: APICallback) {
    request("PUT", params: params, url: url, callback: callback)
  }
  
  /// Performs a `DELETE` request on the API Server
  ///
  /// - parameter params: an optional `Dictionary` containing any parameters required for the request
  /// - parameter url: a `String` containing the route for the API method to be requested
  /// - parameter callbck: an `APICallback` that will either contain the json of the
  /// requested object or an error if the request failed
  ///
  /// See also: `APICallback`
  public func delete(params: [ String : String ]?, url: String, callback: APICallback) {
    request("DELETE", params: params, url: url, callback: callback)
  }
  
  //MARK: Private Methods
  
  /// Decorates the http request with required headers, 
  /// attaches params and dispatches the request.
  /// 
  /// Once a response is received the returned response or error is parsed
  /// and returned via the callback
  /// 
  /// Note: This is a private method not available to client applications.
  /// In most cases this method will not need to be accessed directly and
  /// access should be through the get, post, put and delete methods
  ///
  /// - parameter type: The `string` for the request type (GET, POST, PUT or DELETE)
  /// - parameter params: An optional `Dictionary` containing any parameters required for the request
  /// - parameter url: a `String` containing the route for the API method to be requested
  /// - parameter callbck: an `APICallback` that will either contain the json of the
  /// requested object or an error if the request failed
  ///
  /// See also: `APICallback`, `get()`, `post()`, `put()`, 'delete()'
  private func request(type: String, params: [ String : AnyObject ]?, url: String, callback: APICallback) {
    let request = NSMutableURLRequest(URL: NSURL(string: apiURL + url)!)
    let session = NSURLSession.sharedSession()
    request.HTTPMethod = type
    
    let err: NSError?
    
    if let parameters = params {
      do {
        request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(parameters, options: [])
      } catch let error as NSError {
        err = error
        request.HTTPBody = nil
        print("error attaching params: \(err?.localizedDescription)")
      }
    }
    
    
    //Build & App Specific Headers:
    request.addValue(agentHeader.constructHeader(), forHTTPHeaderField: "x-odd-user-agent")
    request.addValue("Bearer \(userAuthToken)", forHTTPHeaderField: "Authorization")
    //Utility Headers:
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.addValue(NSLocale.currentLocale().localeIdentifier, forHTTPHeaderField: "Accept-Language")
    
    #if os(tvOS)
      request.addValue("tvOS", forHTTPHeaderField: "User-Agent")
    #else
      if UIDevice.currentDevice().userInterfaceIdiom == .Pad  {
        request.addValue("iPad", forHTTPHeaderField: "User-Agent")
      } else {
        request.addValue("iPhone", forHTTPHeaderField: "User-Agent")
      }
    #endif  
    
    let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error -> Void in
      
      if let e = error {
        if e.code < -999 { // NSURLError.NotConnectedToInternet.rawValue {
          NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: OddConstants.OddConnectionOfflineNotification, object: e) )
        }
        callback(nil, e)
        return
      }
      
      //      let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)!
      //      println("JSON String: \(jsonStr)")
      //
      
      var cacheTime: Int?
      if let res = response as! NSHTTPURLResponse! {

        // headers are defined as [String : String] so...
        if let cacheStr = res.allHeaderFields["Cache-Control"] as? String {
          let cacheArray = cacheStr.componentsSeparatedByString(", ")
          let maxAge = cacheArray[1]
          let cache = maxAge.stringByReplacingOccurrencesOfString("max-age=", withString: "")
          cacheTime = Int(cache)
        }

        if res.statusCode == 401 { // unauthorized
          print("Error server responded with 401: Unauthorized to \(url)")
          OddGateKeeper.sharedKeeper.blowAwayCredentials()
          NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "unauthorizedResponseReturned", object: nil))
        }
        
        if res.statusCode == 201 {
          OddLogger.info("Server responded with \(res.statusCode). Object created.")
          callback(nil, nil)
          return
        }
        
        if res.statusCode != 200 {
          OddLogger.error("Error, server responded with: \(res.statusCode)" )
          var errorMessage = "No data returned"
          if let localData = data {
            errorMessage = self.parseError(localData)
          }
          let e = NSError(domain: "ODD", code: 100, userInfo: [ "statusCode": res.statusCode, "message" : errorMessage ])
          callback(nil, e)
          return
        }
      }
      
      if error == nil {
        self.parseData(data, cacheTime: cacheTime, callback: callback)
      }
    })
    
    task.resume()
  }
  
  
  /// Parses an error returned from the server.
  ///
  /// - parameter data: an `NSData` object containing the error returned from the server
  /// - returns: A `String` with the error if in the correct error message format or "undefined"
  ///
  /// Note: if the server returns an error message in the format "message" : <the error message>
  /// this method returns the message string otherwise "undefined"
  private func parseError(data: NSData) -> String {
    //    let serializationError: NSError?
    //    let json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves) as? [ String:AnyObject ]
    //
    //
    var serializationError: NSError?
    var json: AnyObject?
    do {
      json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves)
    } catch let error as NSError {
      serializationError = error
      json = nil
    }
    
    
    if(serializationError != nil) {
      return "undefined"
    } else {
      if let jsonMessage = json {
        if let message = jsonMessage["message"] as? String {
          return message
        } else {
          if let message = jsonMessage["emails.address"] as? Array<String> {
            print("Email \(message[0])")
            return "Email \(message[0])"
          }
        }
        
      }
      return "undefined"
    }
  }
  
  /// Parses the data returned from an http request
  ///
  /// - parameter data: An optional `NSData` object containing the server response, if any
  /// - parameter callbck: an `APICallback` that will either contain the json of the
  /// response or nil if no data is found or an error occurred serializing the response
  private func parseData(data: NSData?, cacheTime: Int? = nil, callback: APICallback) {
    
    func reportJsonError() {
      print("Error could not parse JSON")
      let e = NSError(domain: "Oddworks", code: 101, userInfo: [ "JSON" : "No data found" ])
      callback(nil, e)
    }
    
    if data == nil {
      reportJsonError()
    } else {
      
      var serializationError: NSError?
      //    var json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &serializationError) as? [ String:AnyObject ]
      
      var json: AnyObject?
      do {
        json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
        
        if let cacheTime = cacheTime {
          let mutableDict = NSMutableDictionary(dictionary: (json as? NSDictionary)!)
          if let theData = mutableDict["data"] as? NSMutableDictionary {
              theData.setObject(cacheTime, forKey: "cacheTime")
              json = mutableDict
          }
        }

      } catch let error as NSError {
        serializationError = error
        json = nil
      }
      
      //    if let response: AnyObject = json {
      //      if response.isKindOfClass(NSArray) {
      //        println("***** JSON ARRAY *****")
      //      } else {
      //        println("***** JSON DICTIONARY *****")
      //      }
      //    }
      
      if(serializationError != nil) {
        callback(nil, serializationError)
      }
      else {
        if let parsedJSON: AnyObject = json {
          callback(parsedJSON, nil)
        }
        else {
          reportJsonError()
        }
      }
    }
  }
  
}
