//
//  APIManager.swift
//  Taya-Prototype-Victor
//
//  Created by Modi (Victor) Li.
//

import Foundation
import SwiftUI
import Alamofire

struct Empty: Codable { }

protocol APIItem {
    var url: String { get }
    var httpMethod: HTTPMethod { get }
    
    associatedtype RequestData: Encodable = Empty
    associatedtype ResponseData: Decodable = Empty
}

class APICall<T: APIItem> {
    
    let apiItem: T
    let requestData: T.RequestData
    var onSuccess: ((T.ResponseData) -> Void)?
    var onError: ((String) -> Void)?
    
    init(apiItem: T, requestData: T.RequestData) {
        self.apiItem = apiItem
        self.requestData = requestData
    }
    
    func onSuccess(_ handler: @escaping (T.ResponseData) -> Void) -> Self {
        self.onSuccess = handler
        return self
    }
    
    func onError(_ handler: @escaping (String) -> Void) -> Self {
        self.onError = handler
        return self
    }
    
    func onFailure(_ handler: @escaping (String) -> Void) -> Self {
        self.onError = handler
        return self
    }
    
    func execute() {
        Task {
            do {
                let response = try await APIManager.shared.makeHTTPRequest(apiItem: apiItem, requestData: requestData)
                await MainActor.run {
                    onSuccess?(response)
                }
            } catch let responseError as APIResponseError {
                await MainActor.run {
                    onError?(responseError.error.message)
                }
            }
            catch {
                await MainActor.run {
                    onError?(error.localizedDescription)
                }
            }
        }
    }
    
    func call() async throws -> T.ResponseData {
        return try await APIManager.shared.makeHTTPRequest(apiItem: apiItem, requestData: requestData)
    }
}

struct APIResponseError: Decodable, Error {
    
    let error: ErrorContent
    
    struct ErrorContent: Decodable {
        let message: String
    }
}


class APIManager {
    
    static let shared = APIManager()
    
    private init () { }
    
    func makeHTTPRequest<T: APIItem>(apiItem: T, requestData: T.RequestData) async throws -> T.ResponseData {
        
        var headers: HTTPHeaders = [
            .contentType("application/json"),
            .accept("application/json")
        ]
        
        headers.add(.authorization(bearerToken: Secrets.openaiAPIKey))
        
        return try await withCheckedThrowingContinuation { continuation in
            
            var encoder: ParameterEncoder {
                switch apiItem.httpMethod {
                case .get, .delete, .head:
                    return URLEncodedFormParameterEncoder(destination: .queryString)
                default:
                    let jsonEncoder = JSONEncoder()
                    jsonEncoder.dateEncodingStrategy = .iso8601
                    return JSONParameterEncoder.json(encoder: jsonEncoder)
                }
            }
            
            AF.request(apiItem.url, method: apiItem.httpMethod, parameters: requestData, encoder: encoder, headers: headers)
                .validate(statusCode: 200..<300)
                .responseDecodable(of: T.ResponseData.self, emptyResponseCodes: []) { response in
                    
                    switch response.result {
                    case .success(let value):
                        continuation.resume(returning: value)
                    case .failure(let afError):
                        if let data = response.data, let apiError = try? JSONDecoder().decode(APIResponseError.self, from: data) {
                            continuation.resume(throwing: apiError)
                            print("API Error: \(apiError)")
                        } else {
                            continuation.resume(throwing: afError)
                            print("Unknown Error: \(afError)")
                        }
                    }
                }
        }
    }
    
}
