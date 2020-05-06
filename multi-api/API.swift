//
//  API.swift
//  multi-api
//
//  Created by Anton Aleksieiev on 06.05.2020.
//  Copyright © 2020 Anton Aleksieiev. All rights reserved.
//

import Foundation
import Alamofire

public class API {
    public static let shared: API = API()
    
    var token: String = ""
    
    public func login(email: String, password: String, callback: @escaping (_ success: Bool,_ message: String) -> Void) {
        let params: Parameters = [
            "email": email,
            "password": password,
            "device_uuid": UUID().uuidString
        ]
        AF.request(
            "https://ingress.entryfy.com/account-app/sessions",
            method: .post,
            parameters: params
        )
            .validate(statusCode: 200..<300)
            .response { [weak self] response in
            debugPrint(response)
            switch response.result {
            case .success(let data):
                guard let data = data else {
                    callback(false, "Cannot deserialize response")
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableLeaves)
                    guard let dict = json as? [String: Any],
                        let token = dict["auth_token"] as? String
                        else {
                        callback(false, "Cannot deserialize response")
                        return
                    }
                    self?.token = token
                    callback(true, "Success login")
                } catch {
                    callback(false, "Cannot deserialize response")
                }
            case .failure(let error):
                guard let data = response.data else {
                    callback(false, error.localizedDescription)
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableLeaves)
                    guard let dict = json as? [String: [String: [String]]],
                        let errors = dict["errors"] else {
                        callback(false, error.localizedDescription)
                        return
                    }
                    
                    callback(false, errors.reversed().map({"\($0.key.capitalizingFirstLetter()): \(($0.value).map({$0.capitalizingFirstLetter()}).joined(separator: ", "))"}).joined(separator: ", "))
                } catch {
                    callback(false, error.localizedDescription)
                }
            }
        }
    }
    
    public func getUser() {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(self.token)",
            "Accept": "application/json"
        ]
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
      return prefix(1).uppercased() + self.lowercased().dropFirst()
    }

    mutating func capitalizeFirstLetter() {
      self = self.capitalizingFirstLetter()
    }
}
