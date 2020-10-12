//
//  RSSconnector.swift
//  SimpleRSS
//
//  Copyright © 2018年 an. All rights reserved.
//

import UIKit

protocol RSSConnectorDelegate: class {
    func connector(_ connector: RSSConnector, didFailedWithError error: Error?)
    func connectorDidFinishDownloading(_ connector: RSSConnector)
}


class RSSConnector: NSObject, URLSessionTaskDelegate, XMLParserDelegate {
    
    // RSSフィードのURL保存key
    private let keyRssUrl = "RssUrl"

    // XMLタグ
    enum Tag: String {
        case rss = "rss"
        case channel = "channel"
        case item = "item"
        case title = "title"
        case link = "link"
        case description = "description"
        case pubDate = "pubDate"
        case enclosure = "enclosure"
    }
    
    // enclosureタグの属性
    enum EnclosureAttribute: String {
        case length = "length"
        case type = "type"
        case url = "url"
    }

    // デリゲート
    weak var delegate: RSSConnectorDelegate?
    
    // RSSフィードのURL
    var rssUrl: String? {
        get {
            return UserDefaults.standard.string(forKey: keyRssUrl)
        }
        set(value) {
            if let value = value, !value.isEmpty {
                UserDefaults.standard.set(value, forKey: keyRssUrl)
            }
            else {
                UserDefaults.standard.removeObject(forKey: keyRssUrl)
            }
        }
    }
    
    // 分析中のXMLタグ
    var isRss = false
    var isChannel = false
    var isItem = false
    
    // 分析中のデータ
    var buffer = ""
    var rssChannel: RSSChannel?
    

    // MARK: -  Public
    /**
     有効なRSSフィードのURLがあるかどうか

     - Returns: RSSフィードの登録状態
     */
    func hasRssUrl() -> Bool {
        if let _ = rssUrl {
            return true
        }
        return false
    }
    
    /**
     RSSをダウンロードする
     */
    func downloadRSSItems() {
        guard let rssUrl = rssUrl else {
            return
        }
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        let url = URL(string: rssUrl)!
        
        let task = session.dataTask(with: url) {
            (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error, let delegate = self.delegate {
                delegate.connector(self, didFailedWithError: error)
            }
            else if let _ = response,
                let data = data,
                let _ = String(data: data, encoding: .utf8) {
                self.parse(data: data)
            }
            else {
                if let delegate = self.delegate {
                    delegate.connector(self, didFailedWithError: nil)
                }
            }
        }
        task.resume()
    }
    
    
    // MARK: -  XMLParserDelegate
    
    func parserDidEndDocument(_ parser: XMLParser) {
        if let delegate = delegate {
            if let channel = rssChannel, channel.items.count > 0 {
                delegate.connectorDidFinishDownloading(self)
            }
            else {
                delegate.connector(self, didFailedWithError: nil)
            }
        }
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if let elementTag = Tag(rawValue: elementName) {
            switch elementTag {
            case .rss:
                isRss = true
                
            case .channel:
                isChannel = true
                
            case .item:
                isItem = true
                if let channel = rssChannel {
                    channel.items += [RSSItem()]
                }
                
            case .enclosure:
                if let type = attributeDict[EnclosureAttribute.type.rawValue], isImage(type: type) {
                    if let channel = rssChannel, let item = channel.items.last {
                        item.enclosureUrl = attributeDict[EnclosureAttribute.url.rawValue]
                    }
                }

            default:
                buffer = ""
                break
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {        
        guard let channel = rssChannel else {
            assertionFailure("rssChannel is nil")
            return
        }
        
        if let elementTag = Tag(rawValue: elementName) {
            switch elementTag {
            case .rss:
                isRss = false
                
            case .channel:
                isChannel = false
                
            case .item:
                isItem = false
                
            case .title:
                if isItem, let item = channel.items.last {
                    item.title = buffer
                }
                else if isChannel {
                    channel.title = buffer
                }

            case .link:
                if isItem, let item = channel.items.last {
                    item.link = buffer
                }
                else if isChannel {
                    channel.link = buffer
                }

            case .description:
                if isItem, let item = channel.items.last {
                    item.itemDescription = buffer
                }

            case .pubDate:
                if isItem, let item = channel.items.last {
                    item.pubDate = buffer
                }
                
            default:
                break
                
            }
        }
        
        buffer = ""
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }

    
    // MARK: -  Private

    /**
     XMLをパースする

     - Parameter data: XMLデータ
     */
    private func parse(data: Data) {
        rssChannel = RSSChannel()

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }
    
    /**
     type属性から画像か判定する
     
     - Parameter type: type属性値
     
     - Returns: true=画像、 false=それ以外
     */
    private func isImage(type: String) -> Bool {
        return type.contains("image")
    }
}
