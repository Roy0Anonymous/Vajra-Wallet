//
//  FileMgr.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//
//
import Foundation

class FileHandler {
    static let fileManager = FileManager.default
    static func getDocumentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    static func createDirectory(path: String) {
        let url = getDocumentsDirectory().appendingPathComponent(path)
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            print("Could not create a directory: \(error)")
        }
    }

    static func writeData(data: Data, path: String) {
        let url = getDocumentsDirectory().appendingPathComponent(path)
        do {
            try data.write(to: url)
        } catch {
            print("Could not write data to the directory: \(error)")
        }
    }

    static func fileExists(path: String) -> Bool {
        let url = getDocumentsDirectory().appendingPathComponent(path)
        let res = fileManager.fileExists(atPath: url.path)
        return res
    }

    static func readData(path: String) -> Data? {
        let url = getDocumentsDirectory().appendingPathComponent(path)
        do {
            return try Data(contentsOf: url)
        } catch {
            print("Could not read data from the path: \(error)")
            return nil
        }
    }

    static func contentsOfDirectory(atPath: String? = nil, regex: String? = nil) throws -> [URL] {

        let url: URL
        if let path = atPath {
            url = getDocumentsDirectory().appendingPathComponent(path)
        }
        else {
            url = getDocumentsDirectory()
        }

        let content: [URL]
        if let regex = regex {
            let urlRegex = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
            content = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil).filter { url in
                let range = NSRange(location: 0, length: url.absoluteString.count)
                if urlRegex.firstMatch(in: url.absoluteString, range: range) != nil {
                    return true
                } else {
                    return false
                }
            }
        }
        else {
            content = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        }
        return content
    }

    static func readData(url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }
}
