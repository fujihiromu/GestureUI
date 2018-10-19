
import UIKit
import AVFoundation

open class Music: NSObject, AVAudioPlayerDelegate {
    var audioPlayer = [AVAudioPlayer?]()
    
    override init(){
        
    }

    public func audioSetup(name :String,kind :String){
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
    
    public func playAudiofile(number : Int){
        if(number < audioPlayer.count){
            if(audioPlayer[number]!.isPlaying){
                audioPlayer[number]!.currentTime = 0
                audioPlayer[number]!.play()
            }else{
                audioPlayer[number]!.play()
            }
        }
    }
 
}
