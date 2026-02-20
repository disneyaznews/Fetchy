// AppGroup.swift
// 共通のApp Group IDユーティリティ
import Foundation

/// Info.plistのAppGroupIdentifierからIDを取得し、なければ従来値にフォールバック
struct AppGroup {
    static var identifier: String {
        if let id = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String {
            return id
        }
        return "group.com.nisesimadao.Fetchy"
    }
}
