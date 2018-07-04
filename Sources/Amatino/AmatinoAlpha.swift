//
//  AmatinoAlpha.swift
//  Amatino Swift
//
//  author: hugh@blinkybeach.com
//

import Foundation

public class AmatinoAlpha
{
    private let session: Session
    
    public static func create(
        userId: Int,
        secret: String,
        callback: (Error?, AmatinoAlpha?) -> Void
        ) {
        
    }
    
    public static func create(
        email: String,
        secret: String,
        callback: @escaping (Error?, AmatinoAlpha?) -> Void
        ) {
        let _ = Session.create(
            email: email,
            secret: secret,
            callback: {(error: Error?, session: Session?) in
                guard error == nil else {callback(error, nil); return}
                let alpha = AmatinoAlpha(session: session!)
                callback(nil, alpha)
                return
        })
    }
    
    public init(session: Session)  {
        self.session = session
        return
    }
    
    public func request<T: Encodable>(
        path: String,
        method: HTTPMethod,
        queryString: String?,
        body: Array<T>?,
        readyCallback: @escaping (_: Error?, _: Data?) -> Void
    ) throws -> Void {

        let requestData: RequestData?
        if body != nil {
            requestData = try RequestData(arrayData: body!)
        } else {
            requestData = nil
        }
        
        let urlParameters: UrlParameters?
        if queryString != nil {
            urlParameters = UrlParameters(fromRawQuery: queryString!)
        } else {
            urlParameters = nil
        }
        
        let _ = try AmatinoRequest(
            path: path,
            data: requestData,
            session: session,
            urlParameters: urlParameters,
            method: method,
            callback: readyCallback
        )
    }
}
