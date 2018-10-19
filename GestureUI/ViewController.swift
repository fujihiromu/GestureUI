import UIKit
import CoreBluetooth
import AVFoundation

class ViewController: UIViewController, CBCentralManagerDelegate, AVAudioPlayerDelegate,CBPeripheralDelegate{
    
    private var isScanning = false
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    var audioPlayer = [AVAudioPlayer?]()
    private var DEVICE_UUID = "00002A6E-0000-1000-8000-00805F9B34FB"
    private var DEVICE_CHAR_UUID = "00002A6E-0000-1000-8000-00805F9B34FB"
    override func viewDidLoad() {
        super.viewDidLoad()
        audioSetup(name: "BGM", kind: "mp3")
        audioSetup(name: "tana_01", kind: "mp3")
        audioSetup(name: "tana_02", kind: "mp3")
        audioSetup(name: "tana_03", kind: "mp3")
        audioSetup(name: "tana_04", kind: "mp3")
        audioSetup(name: "not", kind: "mp3")
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
        print(data)
        var str : String = String(describing: data)
        //なぜか＜＞がのってくるので除去
        if let range = str.range(of: "<"){
            str.removeSubrange(range)
        }
        if let range = str.range(of: ">"){
            str.removeSubrange(range)
        }
        print(str)
        decision(str: str)
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
    func audioSetup(name :String,kind :String){
        var samplePlayer:AVAudioPlayer!
        // 再生する audio ファイルのパスを取得
        let audioPath = Bundle.main.path(forResource: name, ofType:kind)!
        let audioUrl = URL(fileURLWithPath: audioPath)
        // auido を再生するプレイヤーを作成する
        var audioError:NSError?
        do {
            samplePlayer = try AVAudioPlayer(contentsOf: audioUrl)
        } catch let error as NSError {
            audioError = error
            samplePlayer = nil
        }
        
        // エラーが起きたとき
        if let error = audioError {
            print("Error \(error.localizedDescription)")
        }
        samplePlayer.delegate = self
        samplePlayer.prepareToPlay()
        audioPlayer.append(samplePlayer);
    }
    
    func decision(str : String){
        print(str)
        if(str == "01"){
            Tapped_01();
        }else if(str == "02"){
            Tapped_02();
        }else if(str == "03"){
            Tapped_03();
        }else if(str == "04"){
            Tapped_04();
        }else if(str == "05"){
            Tapped_not();
        }
    }
    
    func Tapped_00() {
        if ( audioPlayer[1]!.isPlaying ){
            audioPlayer[1]!.currentTime = 0
            audioPlayer[1]!.play()
        }
        else{
            audioPlayer[1]!.play()
        }
    }
    // ボタンがタップされた時の処理
    func Tapped_01() {
        if ( audioPlayer[1]!.isPlaying ){
            audioPlayer[1]!.currentTime = 0
            audioPlayer[1]!.play()
        }
        else{
            audioPlayer[1]!.play()
        }
    }
    func Tapped_02() {
        if ( audioPlayer[2]!.isPlaying ){
            audioPlayer[2]!.currentTime = 0
            audioPlayer[2]!.play()
        }
        else{
            audioPlayer[2]!.play()
        }
    }
    func Tapped_03() {
        if ( audioPlayer[3]!.isPlaying ){
            audioPlayer[3]!.currentTime = 0
            audioPlayer[3]!.play()
        }
        else{
            audioPlayer[3]!.play()
        }
    }
    func Tapped_04() {
        if ( audioPlayer[4]!.isPlaying ){
            audioPlayer[4]!.currentTime = 0
            audioPlayer[4]!.play()
        }
        else{
            audioPlayer[4]!.play()
        }
    }
    //    @IBAction func Tapped_BGM(_ sender : UIButton) {
    //        if ( audioPlayer[0]!.isPlaying ){
    //            audioPlayer[0]!.setVolume(0.1, fadeDuration: 60)
    //            audioPlayer[0]!.currentTime = 0
    //            audioPlayer[0]!.play()
    //        }
    //        else{
    //            audioPlayer[0]!.play()
    //        }
    //    }
    func Tapped_not() {
        if ( audioPlayer[5]!.isPlaying ){
            audioPlayer[5]!.currentTime = 0
            audioPlayer[5]!.play()
        }
        else{
            audioPlayer[5]!.play()
        }
    }
    
}


