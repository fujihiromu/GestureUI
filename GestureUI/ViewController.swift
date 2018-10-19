import UIKit
import CoreBluetooth
import AVFoundation

class ViewController: UIViewController, CBCentralManagerDelegate, AVAudioPlayerDelegate,CBPeripheralDelegate,UITableViewDelegate, UITableViewDataSource{
    
    private var isScanning = false
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    var audioPlayer = [AVAudioPlayer?]()
    private var DEVICE_UUID = "00002A6E-0000-1000-8000-00805F9B34FB"
    private var DEVICE_CHAR_UUID = "00002A6E-0000-1000-8000-00805F9B34FB"
    private var music = Music()
    
    @IBOutlet weak var table: UITableView!
    
    // section毎の画像配列
    let imgArray: NSArray = [
        "イラスト１","イラスト２",
        "イラスト３","イラスト４",
        "イラスト５","イラスト６"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        music.audioSetup(name: "BGM", kind: "mp3")
        music.audioSetup(name: "tana_01", kind: "mp3")
        music.audioSetup(name: "tana_02", kind: "mp3")
        music.audioSetup(name: "tana_03", kind: "mp3")
        music.audioSetup(name: "tana_04", kind: "mp3")
//        music.audioSetup(name: "not", kind: "mp3")
        // セントラルマネージャ初期化
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    //    // セントラルマネージャの状態が変化すると呼ばれる
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print ("state: \(central.state)")
    }
    // ペリフェラルへの接続が成功すると呼ばれる
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print ("接続成功!!");
        // サービス探索結果を受け取るためにデリゲートをセット
        peripheral.delegate = self
        // サービス探索開始
        peripheral.discoverServices(nil)
    }
    // ペリフェラルへの接続が失敗すると呼ばれる
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("接続失敗・・・");
        ID.text = "Not Connect"
    }
    // サービス発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("エラー: \(error)")
            return
        }
        guard let services = peripheral.services, services.count > 0 else {
            print("no services")
            return
        }
        print("\(services.count) 個のサービスを発見！ \(services)")
        
        for service in services {
            // キャラクタリスティック探索開始
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    // キャラクタリスティック発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?)
    {
        if let error = error {
            print("エラー: \(error)")
            return
        }
        guard let characteristics = service.characteristics, characteristics.count > 0 else {
            print("no characteristics")
            return
        }
        print("\(characteristics.count) 個のキャラクタリスティックを発見！ \(characteristics)")
        // arm sensorのキャラクタリスティック
        for characteristic in characteristics where characteristic.uuid.isEqual(CBUUID(string: DEVICE_CHAR_UUID)) {
            // 更新通知受け取りを開始する
            peripheral.setNotifyValue(
                true,
                for: characteristic)
        }
    }
    // Notify開始／停止時に呼ばれる  P.231 4-6 notify
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?)
    {
        if let error = error {
            print("Notify状態更新失敗...error: \(error)")
        } else {
            print("Notify状態更新成功！characteristic UUID:\(characteristic.uuid), isNotifying: \(characteristic.isNotifying)")
        }
        ////スキャン開始
        isScanning = true
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    // データ更新時に呼ばれる　notifyの通知が来た場合
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?)
    {
        if let error = error {
            print("データ更新通知エラー: \(error)")
            return
        }
        print("データ更新！ characteristic UUID: \(characteristic.uuid), value: \(characteristic.value!), value: \(characteristic.description)")
        let data = NSData(data: characteristic.value!)
        
        var str : String = String(describing: data)
        //なぜか＜＞がのってくるので除去
        if let range = str.range(of: "<"){
            str.removeSubrange(range)
        }
        if let range = str.range(of: ">"){
            str.removeSubrange(range)
        }
        print(str)
        decisionPlay(str: str)
    }
    
    @IBOutlet weak var ID: UILabel!
    
    ////    // 周辺にあるデバイスを発見すると呼ばれる
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        let messID = peripheral.name
        self.peripheral = peripheral
        let str = peripheral.name
        print("peripheral: \(peripheral)")
        if(str != nil){
            if((str! as NSString).substring(to: 4) == "FUJI"){
                print("????????")
                centralManager.connect(peripheral, options: nil)
                print("peripheral: \(peripheral)")
                print("!!!!!")
                //スキャン停止
                isScanning = false
                centralManager.stopScan()
                ID.text = messID
            }
        }
    }
    @IBAction func scanBtnTapped(sender: UISwitch) {
        if !isScanning {
            isScanning = true
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            sender.isOn = true
            //            sender.setTitle("STOP SCAN", for: .normal)
        } else {
            centralManager.stopScan()
            //            sender.setTitle("START SCAN", for: .normal)
            sender.isOn = false
            isScanning = false
        }
    }
    func decisionPlay(str : String){
        let musicnumber = Int(str,radix:16)!
        music.playAudiofile(number: musicnumber)
    }
    
    
    //Table Viewのセルの数を指定
    func tableView(_ table: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return music.audioPlayer.count
    }
    
    
    //各セルの要素を設定する
    func tableView(_ table: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // tableCell の ID で UITableViewCell のインスタンスを生成
        let cell = table.dequeueReusableCell(withIdentifier: "TableCell",
                                             for: indexPath)
        
        let img = UIImage(named: imgArray[indexPath.row] as! String)
        
        // Tag番号 1 で UIImageView インスタンスの生成
        let imageView = cell.viewWithTag(1) as! UIImageView
        imageView.image = img
        
        // Tag番号 ２ で UILabel インスタンスの生成
        let label1 = cell.viewWithTag(2) as! UILabel
        label1.text = "No." + String(indexPath.row + 1)
        
        // Tag番号 ３ で UILabel インスタンスの生成
//        let label2 = cell.viewWithTag(3) as! UILabel
//        label2.text = String(describing: label2Array[indexPath.row])
        
        return cell
    }
    // Cell の高さを１２０にする
    func tableView(_ table: UITableView,heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 105.0
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    /*
     * 各indexPathのcellのスワイプメニューに表示するデフォルトの削除ボタンのタイトルを指定します．
     * nilを指定するとデフォルトの文字列が表示されます．
     * tableView(_:editActionsForRowAt:)でスワイプメニューをカスタマイズしている際には本メソッドは呼ばれません．
     */
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "OK?"
    }
    
}


