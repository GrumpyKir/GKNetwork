//
//  RemoteFactory.swift
//
//  Created by  Кирилл on 4/12/19.
//  Copyright © 2019 AppCraft. All rights reserved.
//

import GKExtensions

public enum RemoteFactory {
    
    // MARK: - Public methods
    public static func request(path: String, parameters: [String: Any]?, headers: [String: String]?, method: HTTPMethod) -> URLRequest? {
        switch method {
        case .get,
             .head:
            return self.createRequestWithUrlParameters(path: path, parameters: parameters, headers: headers, method: method.stringValue)
        case .post,
             .put,
             .patch,
             .delete:
            return self.createRequestWithBodyParameters(path: path, parameters: parameters, headers: headers, method: method.stringValue)
        default:
            // TODO: Add support to other http methods
            break
        }
        
        return nil
    }
    
    public static func upload(path: String, fileKey: String, files: [RemoteUploadModel], parameters: [String: String]?, headers: [String: String]?) -> URLRequest? {
        let urlString = path
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.stringValue
        
        if let headers = headers {
            for header in headers {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        let boundary = self.generateBoundaryString()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = self.generateBody(with: parameters, fileKey: fileKey, files: files, boundary: boundary)
        
        return request
    }
    
    // MARK: - Private methods
    private static func createRequestWithUrlParameters(path: String, parameters: [String: Any]?, headers: [String: String]?, method: String) -> URLRequest? {
        var parameterString = ""
        if let parameters = parameters {
            parameterString = self.generateUrlString(with: parameters)
        }
        
        var urlString = path
        if !parameterString.isEmpty {
            urlString += "?" + parameterString
        }
        
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let headers = headers {
            for header in headers {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        return request
    }
    
    private static func createRequestWithBodyParameters(path: String, parameters: [String: Any]?, headers: [String: String]?, method: String) -> URLRequest? {
        let urlString = path
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        var jsonData: Data?
        if let parameters = parameters {
            jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        }
        request.httpBody = jsonData
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let headers = headers {
            for header in headers {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        return request
    }
    
    private static func generateUrlString(with parameters: [String: Any]) -> String {
        let parameterArray = parameters.map { key, value -> String in
            guard let escapedKey = key.addingPercentEncodingForUrlQueryValue() else { return "" }
            
            if let stringValue = value as? String {
                guard let escapedValue = stringValue.addingPercentEncodingForUrlQueryValue() else { return "" }
                
                return "\(escapedKey)=\(escapedValue)"
            }
            
            if let arrayValue = value as? [Any] {
                var arrayParameter: [String] = []
                
                for index in 0..<arrayValue.count {
                    var element: String
                    if let stringElement = arrayValue[index] as? String {
                        element = stringElement
                    } else {
                        element = "\(arrayValue[index])"
                    }
                    
                    guard let escapedElement = element.addingPercentEncodingForUrlQueryValue() else { continue }
                    
                    arrayParameter.append("\(escapedKey)[]=\(escapedElement)")
                }
                
                return arrayParameter.joined(separator: "&")
            }
            
            guard let escapedValue = "\(value)".addingPercentEncodingForUrlQueryValue() else { return "" }
            
            return "\(escapedKey)=\(escapedValue)"
        }
        
        return parameterArray.joined(separator: "&")
    }
    
    private static func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    private static func generateBody(with parameters: [String: String]?, fileKey: String, files: [RemoteUploadModel], boundary: String) -> Data {
        var body = Data()
        
        if let parameters = parameters {
            for (key, value) in parameters {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
        
        for file in files {
            let filename = file.filename
            let data = file.data
            let mimetype = data.mimeType
            
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(fileKey)\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(mimetype)\r\n\r\n")
            body.append(data)
            body.append("\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        return body
    }
    
}
