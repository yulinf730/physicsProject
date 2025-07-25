import Foundation

class WrongQuestionManager {
    static let shared = WrongQuestionManager()
    private let key = "WrongQuestionIDsWithAnswer"

    // 新数据结构：错题id -> 用户答案
    func allWrongQuestionDict() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
    }
    // 获取错题id列表
    func allWrongQuestionIDs() -> [String] {
        Array(allWrongQuestionDict().keys)
    }
    // 获取某道题之前错选的答案
    func wrongAnswer(for id: String) -> String? {
        allWrongQuestionDict()[id]
    }
    // 添加错题，带上用户答案
    func addWrongQuestion(id: String, selectedAnswer: String) {
        var dict = allWrongQuestionDict()
        dict[id] = selectedAnswer
        UserDefaults.standard.set(dict, forKey: key)
    }
    func removeWrongQuestion(id: String) {
        var dict = allWrongQuestionDict()
        dict.removeValue(forKey: id)
        UserDefaults.standard.set(dict, forKey: key)
    }
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
