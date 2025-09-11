func TrimString (str: String, start: Int, end: Int) -> String {
    let fromIdx = str.index(str.startIndex, offsetBy: start)
    let toIdx = str.index(str.startIndex, offsetBy: end + 1)
    let substr = str[fromIdx..<toIdx]
    return String(substr)
}
