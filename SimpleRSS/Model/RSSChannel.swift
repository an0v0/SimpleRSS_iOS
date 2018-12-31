//
//  RSSChannel.swift
//  SimpleRSS
//
//  Copyright © 2018年 an. All rights reserved.
//

import UIKit

class RSSChannel {
    let id: String = UUID().uuidString  // 識別子

    var title: String?   // タイトル
    var link: String?    // リンク
    
    var items: [RSSItem] = []    // 記事の配列
}
