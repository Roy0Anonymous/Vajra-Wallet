//
//  DataGetPost.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//
import Foundation

class DataGetPost {
    public static func get(url: URL) -> Data? {
        var result: Data?
        let session = URLSession.shared
        let sem = DispatchSemaphore.init(value: 0)
        let task = session.dataTask(with: url) { (data, response, error) in
            defer { sem.signal() }
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Invalid response")
                return
            }
            guard let data = data else {
                print("No data received")
                return
            }
            result = data
        }
        task.resume()
        sem.wait()
        return result
    }
    public static func post(url: URL, body: String) throws -> Data? {
        var result: Data? = nil
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        let headers = [
            "content-type": "text/plain"
        ]
        request.allHTTPHeaderFields = headers
        request.httpMethod = "POST"
        request.httpBody = body.data(using: String.Encoding.utf8)
        
        let session = URLSession.shared
        let sem = DispatchSemaphore.init(value: 0)
        let task = session.dataTask(with: request) { data, response, error in
            defer { sem.signal() }
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Invalid response")
                return
            }
            guard let data = data else {
                print("No data received")
                return
            }
            result = data
        }
        task.resume()
        sem.wait()
        return result
    }
}
