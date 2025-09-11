import FirebaseFirestore

struct Artifact: Identifiable, Codable {
    var id: String {enName}
    let jpName: String
    let enName: String
    let partNameList: [String]
    let imgUrlList: [URL]
    let twoSetEffectSentence: String
    let fourSetEffectSentence: String
    // ここからはadmin専用
    let hoyolabId: Int
}

// 公式APIのjson解析用
struct ArtifactResponse: Codable {
    struct Data: Codable {
        struct Page: Codable {
            struct Module: Codable {
                struct Component: Codable {
                    let data: String
                }
                
                let components: [Component]
            }
            
            let modules: [Module]
        }
        
        let page: Page
    }
    
    let message: String
    let data: Data
}

struct ArtifactList: Codable {
    struct NameAndIcon: Codable {
        let title: String
        let icon_url: String
    }
    
    let flower_of_life: NameAndIcon
    let plume_of_death: NameAndIcon
    let sands_of_eon: NameAndIcon
    let goblet_of_eonothem: NameAndIcon
    let circlet_of_logos: NameAndIcon
}
