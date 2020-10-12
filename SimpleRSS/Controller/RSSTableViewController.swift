//
//  RSSTableViewController.swift
//  SimpleRSS
//
//  Copyright © 2018年 an. All rights reserved.
//

import UIKit

class RSSTableViewController: UITableViewController, RSSConnectorDelegate {
    
    var rssChannel: RSSChannel?

    override func viewDidLoad() {
        super.viewDidLoad()

        // 引っ張って更新の設定
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(valueChanged(sender:)), for: .valueChanged)
        tableView.addSubview(refresh)
        refreshControl = refresh
        
        // RSSダウンロード開始
        refreshData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IBAction

    @IBAction func onEditButton(_ sender: Any) {
        showInputDialog()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rssChannel?.items.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RSSTableViewCell.identifier, for: indexPath)

        if let rssCell = cell as? RSSTableViewCell, let item = rssChannel?.items[indexPath.row] {
            if let title = item.title {
                rssCell.titleLabel.text = trim(title)
            }
            else {
                rssCell.titleLabel.text = ""
            }
            if let description = item.itemDescription {
                rssCell.contentsLabel.text = trim(description)
            }
            else {
                rssCell.contentsLabel.text = ""
            }
            if let pubDate = item.pubDate {
                rssCell.dateLabel.text = formatPubDate(trim(pubDate))
            }
            else {
                rssCell.dateLabel.text = ""
            }
            if let enclosureUrl = item.enclosureUrl {
                DispatchQueue.global().async {
                    if let url = URL(string: enclosureUrl), let data = try? Data(contentsOf: url) {
                        let image = UIImage(data: data)
                        DispatchQueue.main.async {
                            rssCell.thumbnailView?.image = image
                        }
                    }
                }
            }
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toRSSDetail" {
            if let selectedRow = tableView.indexPathForSelectedRow,
                let link = rssChannel?.items[selectedRow.row].link {
                let rssDetailVC = segue.destination as! RSSDetailViewController
                rssDetailVC.url = link
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let selectedRow = tableView.indexPathForSelectedRow else {
            return false
        }
        
        if let _ = rssChannel?.items[selectedRow.row].link {
            // リンクがある場合は遷移する
            return true
        }
        else {
            // リンクがない場合は遷移しない
            tableView.deselectRow(at: selectedRow, animated: true)
            return false
        }
    }
    
    // MARK: - RSSconnectorDelegate
    
    func connector(_ connector: RSSConnector, didFailedWithError error: Error?) {
        DispatchQueue.main.async {
            if let refresh = self.refreshControl {
                refresh.endRefreshing()
            }
        }
        
        if let error = error {
            print("Error: \(error)")
        }
        else {
            print("Unknown error")
        }
    }
    
    func connectorDidFinishDownloading(_ connector: RSSConnector) {
        setRssChannel(connector.rssChannel)
    }

    
    // MARK: - Private
    
    /**
     文字列から前後の余白を取り除く
     
     - Parameter string: 処理対象文字列
     
     - Returns: 前後の余白を取り除いた文字列
     */
    private func trim(_ string: String) -> String {
        return string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /**
     日付のフォーマットを表示用に変換
     
     - Parameter string: 処理対象文字列
     
     - Returns: 表示用にフォーマット変換した日付文字列
                変換失敗した場合は元の文字列を返す
     */
    private func formatPubDate(_ string: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        
        if let date = formatter.date(from: string) {
            formatter.dateFormat = "yyyy.MM.dd(EEE) HH:mm"
            formatter.locale = Locale(identifier: "ja_JP")
            return formatter.string(from: date)
        }
        else {
            return string
        }
    }
    
    /**
     引っ張って更新
     
     - Parameter sender: 送信元オブジェクト
     */
    @objc private func valueChanged(sender: UIRefreshControl) {
        refreshData()
    }
    
    /**
     RSSダウンロード開始
     */
    private func refreshData() {
        let connector = RSSConnector()
        if connector.hasRssUrl() {
            // RSSフィード登録済
            connector.delegate = self
            connector.downloadRSSItems()
        }
        else {
            // RSSフィード未登録
            showInputDialog()
        }
    }
    
    /**
     RSSフィードデータを表示
     
     - Parameter tmpRssChannel: RSSフィードデータ
     */
    private func setRssChannel(_ tmpRssChannel: RSSChannel?) {
        rssChannel = tmpRssChannel
        DispatchQueue.main.async {
            if let refresh = self.refreshControl {
                refresh.endRefreshing()
            }
            self.title = self.rssChannel?.title
            self.tableView.reloadData()
        }
    }
    
    /**
     RSSフィードURL入力ダイアログ表示
     */
    private func showInputDialog() {
        let alert = UIAlertController(title: "RSSフィードのURLを入力", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: { action -> Void in
            DispatchQueue.main.async {
                if let refresh = self.refreshControl {
                    refresh.endRefreshing()
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "登録", style: .default, handler: { action -> Void in
            if let url = alert.textFields?.first?.text {
                let connector = RSSConnector()
                connector.rssUrl = url
                
                if url.isEmpty {
                    // リストをクリア
                    self.setRssChannel(nil)
                }
                else {
                    // 登録されたRSSフィードを取得
                    connector.delegate = self
                    connector.downloadRSSItems()
                }
            }
        }))
        alert.addTextField(configurationHandler: { textField -> Void in
            let connector = RSSConnector()
            textField.text = connector.rssUrl
        })
        present(alert, animated: true, completion: nil)
    }
}
