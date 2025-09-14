import FirebaseFirestore

struct Weapon: Identifiable, Codable {
    var id: String {enName}
    let attack: Int
    var effectSentence: [String]
    let enName: String
    var finalEffectValue: [Double]
    let imgUrl: URL
    var initialEffectValue: [Double]
    let jpName: String
    let rarity: Int
    let subStatusName: String
    let subStatusValue: Double
    let type: String
    // ここからはadmin専用
    let hoyolabId: Int
    
    // 精錬1の武器効果
    var displayInitialEffect: String {
        var sentence = ""
        for i in 0..<initialEffectValue.count {
            sentence += "\(effectSentence[i])\(initialEffectValue[i])"
        }
        sentence += effectSentence[effectSentence.count - 1]
        return sentence
    }
    
    // 精錬5の武器効果
    var displayFinalEffect: String {
        var sentence = ""
        for i in 0..<finalEffectValue.count {
            sentence += "\(effectSentence[i])\(finalEffectValue[i])"
        }
        sentence += effectSentence[effectSentence.count - 1]
        return sentence
    }

    // effect sentenceの処理
    var getEffect: String {
        // const部分とvar部分からeffectを生成
        get {
            var text = ""
            for i in 0 ..< initialEffectValue.count {
                text += effectSentence[i]
                text += "$(\(initialEffectValue[i]),\(finalEffectValue[i]))"
            }
            text += effectSentence[initialEffectValue.count]
            return text
        }
        // effectのstringからconst部分とvar部分を分割
        set(effect) {
            // 正規表現パターン: ${...} の中身をキャプチャ
            let pattern = #"\$\(([^)]*)\)"#
            
            // 初期化
            var _initialEffectValue: [Double] = []
            var _finalEffectValue: [Double] = []
            var _effectSentence: [String] = []
            
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                let matches = regex.matches(in: effect, range: NSRange(effect.startIndex..., in: effect))
                
                // 数値の抽出
                let values = matches.compactMap {
                    Range($0.range(at: 1), in: effect).map { String(effect[$0]) }
                }
                
                for value in values {
                    let list = value.split(separator: ",")
                    _initialEffectValue.append(Double(list[0]) ?? 0.0)
                    _finalEffectValue.append(Double(list[1]) ?? 0.0)
                }
                
                // string部分の抽出
                var lastIndex = effect.startIndex
                for match in matches {
                    let range = Range(match.range, in: effect)!
                    
                    // ${...} の前の固定部分
                    if lastIndex < range.lowerBound {
                        _effectSentence.append(String(effect[lastIndex..<range.lowerBound]))
                    }
                    lastIndex = range.upperBound
                }
                
                // 最後の残り部分
                if lastIndex < effect.endIndex {
                    _effectSentence.append(String(effect[lastIndex..<effect.endIndex]))
                }
                
                initialEffectValue = _initialEffectValue
                finalEffectValue = _finalEffectValue
                effectSentence = _effectSentence
                
            } catch {
                print("正規表現エラー: \(error)")
            }
        }
    }
}
