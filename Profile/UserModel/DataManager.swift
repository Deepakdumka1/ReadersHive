import Foundation

enum DataManagerError: Error {
    case fileNotFound
    case decodingError(Error)
}

final class DataManager {
    static let shared = DataManager()
    
    private init() {}
    
    /// Statically loads a strictly bundled read-only JSON file using the robust generic generic
    func loadJSON<T: Decodable>(filename: String, type: T.Type) throws -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw DataManagerError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("DataManager Decoding Exception: \(error)")
            throw DataManagerError.decodingError(error)
        }
    }
}
