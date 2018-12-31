//
//  RSSDetailViewController.swift
//  SimpleRSS
//
//  Copyright © 2018年 an. All rights reserved.
//

import UIKit
import WebKit

class RSSDetailViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    
    var url: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // URL読み込み
        if let url = URL(string: url) {
            webView.load(URLRequest(url: url))
        }
        // delegateを設定
        webView.navigationDelegate = self
        webView.uiDelegate = self
    }
    
    // MARK: - IBAction
    /**
     戻るボタン
     - Parameter sender: ボタン
     */
    @IBAction func onBackButton(_ sender: Any) {
        if webView.canGoBack {
            webView.goBack()
            updateButtons()
        }
    }
    
    /**
     進むボタン
     - Parameter sender: ボタン
     */
    @IBAction func onForwardButton(_ sender: Any) {
        if webView.canGoForward {
            webView.goForward()
            updateButtons()
        }
    }
    
    /**
     更新ボタン
     - Parameter sender: ボタン
     */
    @IBAction func onReloadButton(_ sender: Any) {
        webView.reload()
    }
    
    // MARK: - WKNavigationDelegate
    /**
     WebView読み込み開始前
     
     - Parameter webView: WebView
     - Parameter navigation: 実行中のナビゲーション
     */
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    /**
     WebView読み込み開始時
     
     - Parameter webView: WebView
     - Parameter navigation: 実行中のナビゲーション
     */
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // ネットワークインジケータ表示
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    /**
     WebView読み込み完了時
     
     - Parameter webView: WebView
     - Parameter navigation: 実行中のナビゲーション
     */
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // ネットワークインジケータ非表示
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        // 画面更新
        didFinish()
    }
    
    /**
     WebView遷移時失敗時
     
     - Parameter webView: WebView
     - Parameter navigation: 実行中のナビゲーション
     - Parameter error: エラー情報
     */
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        didfail(withError: error)
    }
    
    /**
     WebView読み込み失敗時
     
     - Parameter webView: WebView
     - Parameter navigation: 実行中のナビゲーション
     - Parameter error: エラー情報
     */
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        didfail(withError: error)
    }
    
    // MARK: - WKUIDelegate
    /**
     WebView作成時
     
     - Parameter webView: WebView
     - Parameter configuration: 新しいWebViewの設定
     - Parameter navigationAction: 元になったWKNavigationAction
     - Parameter windowFeatures: 新しいWebViewの属性
     
     - Returns: 新しいWebViewまたはnil
     */
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let _ = navigationAction.targetFrame {
        }
        else {
            // target="_blank" の場合
            webView.load(navigationAction.request)
        }
        
        return nil
    }
    
    
    // MARK: - Private
    /**
     戻る・進むボタン更新
     */
    private func updateButtons() {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
    }
    
    /**
     エラー表示
     - Parameter error: エラー情報
     */
    private func didfail(withError error: Error) {
        // ネットワークインジケータ非表示
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        switch (error as NSError).code {
        case NSURLErrorCancelled:
            // エラーではない
            didFinish()

        default:
            // エラーページ表示
            let html = "<html><head><title>エラー</title><meta charset='UTF-8'></head><body><h1>Webページを表示できません</h1></body></html>"
            webView.loadHTMLString(html, baseURL: nil)
        }
    }
    
    /**
     成功時画面更新
     */
    private func didFinish() {
        // タイトル設定
        navigationItem.title = webView.title
        // 戻る・進むボタン更新
        updateButtons()
    }
}
