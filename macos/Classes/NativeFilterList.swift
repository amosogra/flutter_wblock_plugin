import Foundation

struct NativeFilterList: Codable {
    let id: String
    let name: String
    let url: URL
    let category: String
    var isSelected: Bool
    let description: String
    var version: String
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "url": url.absoluteString,
            "category": category,
            "isSelected": isSelected,
            "description": description,
            "version": version
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> NativeFilterList? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let urlString = dict["url"] as? String,
              let url = URL(string: urlString),
              let category = dict["category"] as? String else {
            return nil
        }
        
        return NativeFilterList(
            id: id,
            name: name,
            url: url,
            category: category,
            isSelected: dict["isSelected"] as? Bool ?? false,
            description: dict["description"] as? String ?? "",
            version: dict["version"] as? String ?? ""
        )
    }
}

struct FilterStats {
    let enabledListsCount: Int
    let totalRulesCount: Int
    
    func toDictionary() -> [String: Any] {
        return [
            "enabledListsCount": enabledListsCount,
            "totalRulesCount": totalRulesCount
        ]
    }
}
