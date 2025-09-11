//
//  ParameterString.swift
//  artifacts analyzer admin app
//
//  Created by 釆山怜央 on 2025/09/02.
//

func removeTrailingPercent(str: String) -> String {
    if str.hasSuffix("%") {
        return String(str.dropLast())
    } else {
        return str
    }
}

func addTrailingPercent(key: String, value: Double) -> String {
    if key != "元素熟知" {
        return "\(value)%"
    } else {
        return "\(value)"
    }
}
