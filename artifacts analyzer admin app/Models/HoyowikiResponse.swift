// 公式APIのjson解析用
struct HoyowikiResponse: Codable {
    struct Data: Codable {
        struct Page: Codable {
            struct Module: Codable {
                struct Component: Codable {
                    let data: String
                }
                
                let components: [Component]
            }
            
            let icon_url: String
            let modules: [Module]
            let filter_values: FilterValues?
        }
        
        let page: Page
    }
    
    let message: String
    let data: Data
}


// 公式レスポンス weapon用
struct FilterValues: Codable {
    struct WeaponType: Codable {
        let values: [String]
    }
    
    struct WeaponProperty: Codable {
        let values: [String]
    }
    
    struct WeaponRarity: Codable {
        let values: [String]
    }
    
    let weapon_type: WeaponType?
    let weapon_property: WeaponProperty?
    let weapon_rarity: WeaponRarity?
}

struct WeaponBasicInfo: Codable {
    let key: String
    let value: [String]
}

struct WeaponAscension: Codable {
    struct Combat: Codable {
        let key: String
        let values: [String]
    }
    
    let key: String
    let combatList: [Combat]
    let materials: [String]?
    let id: String
}


// 公式APIレスポンス artifact用
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
