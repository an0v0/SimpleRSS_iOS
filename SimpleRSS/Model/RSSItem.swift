//
//  RSSItem.swift
//  SimpleRSS
//
//  Copyright © 2018年 an. All rights reserved.
//

import UIKit

class RSSItem {
    let id: String = UUID().uuidString  // 識別子
    var read: Bool = false  // 既読状態
    
    var title: String?    // 記事のタイトル
    var link: String?    // 記事のリンク
    var itemDescription: String? // 記事の詳細
    var pubDate: String? // 記事の日付
    var enclosureUrl: String?   // サムネイル
}
