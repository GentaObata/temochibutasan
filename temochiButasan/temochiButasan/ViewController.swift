//
//  ViewController.swift
//  temochiButasan
//
//  Created by obata on 2018/01/04.
//  Copyright © 2018年 obata. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    //触覚をやるやつをインスタンス化
    let generator = UIImpactFeedbackGenerator(style: .light)
    let mediumgenerator = UIImpactFeedbackGenerator(style: .medium)
    let heavygenerator = UIImpactFeedbackGenerator(style: .heavy)
    //加速度センサー使うためのインスタンス
    let motion = CMMotionManager()
    var distance:Double!
    var count:Int = 0
    var xHankei:Double!
    var yHankei:Double!
    //画面の端の座標
    var hani_x_hashi:Double!
    var hani_y_hashi:Double!
    //指と豚の位置のギャップ
    var gapX:CGFloat = 0.0  // x座標
    var gapY:CGFloat = 0.0  // y座標
    //一個前のぶたのいち
    var buta_pre_x: CGFloat!
    var buta_pre_y: CGFloat!
    //タッチしてからの累積移動距離
    var accDistance: Double = 0
    //タイマーをインスタンス化
    var timer: Timer!
    //ぶたの画像をインスタンス化
    //let butaImage = UIImage(named: "buta2.png")!
    //ぶたのUIImageViewをインスタンス化
    let butaView = UIImageView(image: UIImage(named: "buta2.png"))
    let imWidth = UIImage(named: "buta2.png")!.size.width
    let imHeight = UIImage(named: "buta2.png")!.size.height
    //豚の速度
    var buta_velo: Double = 0
    var theta: Double = 0
    //豚の加速度
    let buta_accl: Double = -200
    let g: Double = 9800*414/(63.5*30)
    //壁にぶつかった時の速度に減衰
    let kabe_gensui: Double = -200
    //経過時間をはかるために現在の時刻
    var beforeTime = NSDate()
    //豚の動く前の位置
    var buta_prepre_x: CGFloat = 0
    var buta_prepre_y: CGFloat = 0
    //単位時間
    let dt: Double = 0.001
    //壁にぶつかった時にどのくらいかの衝撃の閾値
    let heavy: Double = 3000
    let medium: Double = 1000
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //豚を画面に配置，タグを1に，操作可能とする
        butaView.frame = CGRect(x:0, y:0, width:self.view.bounds.width/3, height:self.view.bounds.width*imHeight/(3*imWidth))
        butaView.center = CGPoint(x:view.center.x, y: view.center.y - 200)
        butaView.isUserInteractionEnabled = true
        butaView.tag = 1
        view.addSubview(butaView)
        xHankei = Double((butaView.frame.maxX - butaView.frame.minX)/2)
        yHankei = Double((butaView.frame.maxY - butaView.frame.minY)/2)
        hani_x_hashi = Double(self.view.bounds.maxX)
        hani_y_hashi = Double(self.view.bounds.maxY)
        buta_pre_x = butaView.center.x
        buta_pre_y = butaView.center.y
        self.startAccelerometers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //画面が表示される直前まいかい呼ばれる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    //指の起き始め
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 最初にタッチした指のみ取得
        if let touch = touches.first {
            if let touchedView = touch.view {
                // tagでbutaかそうでないかを判断する
                if touchedView.tag == 1 {
                    buta_velo = 0
                    theta = 0
                    //タイマーを止める
                    timer.invalidate()
                    // タッチした場所とタッチしたビューの中心座標がどうずれているか？
                    gapX = touch.location(in: view).x - touchedView.center.x
                    gapY = touch.location(in: view).y - touchedView.center.y
                    touchedView.center = CGPoint(x: touch.location(in: view).x - gapX, y: touch.location(in: view).y - gapY)
                    buta_pre_x = touchedView.center.x
                    buta_pre_y = touchedView.center.y
                    accDistance = 0
                }
            }
        }
    }
    //指を動かした時
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            // タッチしたビューをviewプロパティで取得する
            if let touchedView = touch.view {
                // tagでぶたかそうでないかを判断する
                if touchedView.tag == 1 {
                    buta_prepre_x = touchedView.center.x
                    buta_prepre_y = touchedView.center.y
                    var next_x = touch.location(in: view).x - gapX
                    var next_y = touch.location(in: view).y - gapY
                    //豚のセンターと半径から画面からはみ出していたら元に戻す処理
                    if Double(touchedView.center.x) - xHankei <= 0{
                        next_x = CGFloat(xHankei)
                        if Double(touch.location(in: view).x - gapX) - xHankei > 0{
                            next_x = touch.location(in: view).x - gapX
                        }
                    }
                    if Double(touchedView.center.x) + xHankei >= hani_x_hashi{
                        next_x = CGFloat(hani_x_hashi - xHankei)
                        if Double(touch.location(in: view).x - gapX) + xHankei < hani_x_hashi{
                            next_x = touch.location(in: view).x - gapX
                        }
                    }
                    if Double(touchedView.center.y) - yHankei <= 0{
                        next_y = CGFloat(yHankei)
                        if Double(touch.location(in: view).y - gapY) - yHankei > 0{
                            next_y = touch.location(in: view).y - gapY
                        }
                    }
                    if Double(touchedView.center.y) + yHankei >= hani_y_hashi{
                        next_y = CGFloat(hani_y_hashi - yHankei)
                        if Double(touch.location(in: view).y - gapY) + yHankei < hani_y_hashi{
                            next_y = touch.location(in: view).y - gapY
                        }
                    }
                    // gapX,gapYの取得は行わない
                    touchedView.center = CGPoint(x: next_x, y: next_y)
                    //豚の距離によって触角を誘発する
                    butaMoveImpact(touchedView.center.x,touchedView.center.y)
                    beforeTime = NSDate()
                }
            }
        }
    }
    //指を離した時
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if let touchedView = touch.view {
                // tagでbutaかそうでないかを判断する
                if touchedView.tag == 1 {
                    // gapXとgapYの初期化
                    gapX = 0.0
                    gapY = 0.0
                    let currentTime = NSDate()
                    let pastTime = currentTime.timeIntervalSince(beforeTime as Date)
                    let distance_x:Double = Double(butaView.center.x - buta_prepre_x)
                    let distance_y:Double = Double(butaView.center.y - buta_prepre_y)
                    distance = sqrt(pow(distance_x, 2)+pow(distance_y, 2))
                    buta_velo = distance/Double(pastTime)
                    theta = atan2(distance_y,distance_x)
                    //タイマーをスタート
                    self.startAccelerometers()
                }
            }
        }
    }
    
    //タッチをキャンセルした時
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // touchesEndedと同じ処理
        self.touchesEnded(touches, with: event)
    }
    
    //豚が一定距離移動したら衝撃をおこすための関数
    func butaMoveImpact(_ x: CGFloat, _ y: CGFloat){
        generator.prepare()
        //print(touch.location(in: view))
        let distance_x:Double = Double(buta_pre_x - x)
        let distance_y:Double = Double(buta_pre_y - y)
        distance = pow(distance_x, 2)+pow(distance_y, 2)
        accDistance = accDistance + distance
        if(accDistance > 300){
            generator.impactOccurred()
            accDistance = 0
        }
        buta_pre_x = x
        buta_pre_y = y
    }
    
    //単位時間ごとに豚の位置を変更する関数
    func butaMove(_ x: Double , _ y: Double){
        generator.prepare()
        //壁だったら速度を反転させる
        if Double(butaView.center.x) - xHankei <= 0 && buta_velo*cos(theta) < 0{
            //速さ次第で衝撃をだす
            if fabs(buta_velo*cos(theta)) > heavy{
                heavygenerator.impactOccurred()
            }
            else if fabs(buta_velo*cos(theta)) > medium{
                mediumgenerator.impactOccurred()
            }
            else if fabs(buta_velo*cos(theta)) > g*dt + 10{
                generator.impactOccurred()
            }
            //速度をxとyに分解して，xの部分だけ減衰させる．そのあとxとyを合成した速度を再び求める．同様にθも
            var buta_velo_x = buta_velo*cos(theta) - kabe_gensui
            if buta_velo_x > 0{
                buta_velo_x = 0
            }
            buta_velo = sqrt(pow(buta_velo_x, 2)+pow(buta_velo*sin(theta), 2))
            theta = Double.pi - atan2(buta_velo*sin(theta),buta_velo_x)
        }
        if Double(butaView.center.x) + xHankei >= hani_x_hashi && buta_velo*cos(theta) > 0{
            if fabs(buta_velo*cos(theta)) > heavy{
                heavygenerator.impactOccurred()
            }
            else if fabs(buta_velo*cos(theta)) > medium{
                mediumgenerator.impactOccurred()
            }
            else if fabs(buta_velo*cos(theta)) > g*dt + 10{
                generator.impactOccurred()
            }
            var buta_velo_x = buta_velo*cos(theta) + kabe_gensui
            if buta_velo_x < 0{
                buta_velo_x = 0
            }
            buta_velo = sqrt(pow(buta_velo_x, 2)+pow(buta_velo*sin(theta), 2))
            theta = Double.pi - atan2(buta_velo*sin(theta),buta_velo_x)
        }
        if Double(butaView.center.y) - yHankei <= 0 && buta_velo*sin(theta) < 0{
            if fabs(buta_velo*sin(theta)) > heavy{
                heavygenerator.impactOccurred()
            }
            else if fabs(buta_velo*sin(theta)) > medium{
                mediumgenerator.impactOccurred()
            }
            else if fabs(buta_velo*sin(theta)) > g*dt + 10{
                generator.impactOccurred()
            }
            var buta_velo_y = buta_velo*sin(theta) - kabe_gensui
            if buta_velo_y > 0{
                buta_velo_y = 0
            }
            buta_velo = sqrt(pow(buta_velo_y, 2)+pow(buta_velo*cos(theta), 2))
            theta = -atan2(buta_velo_y,buta_velo*cos(theta))
        }
        if Double(butaView.center.y) + yHankei >= hani_y_hashi && buta_velo*sin(theta) > 0{
            if fabs(buta_velo*sin(theta)) > heavy{
                heavygenerator.impactOccurred()
            }
            else if fabs(buta_velo*sin(theta)) > medium{
                mediumgenerator.impactOccurred()
            }
            else if fabs(buta_velo*sin(theta)) > g*dt + 10{
                generator.impactOccurred()
            }
            var buta_velo_y = buta_velo*sin(theta) + kabe_gensui
            if buta_velo_y < 0{
                buta_velo_y = 0
            }
            buta_velo = sqrt(pow(buta_velo_y, 2)+pow(buta_velo*cos(theta), 2))
            theta = -atan2(buta_velo_y,buta_velo*cos(theta))
            
        }
        let next_x_pos: CGFloat = butaView.center.x + CGFloat(buta_velo*cos(theta)*dt)
        let next_y_pos: CGFloat = butaView.center.y + CGFloat(buta_velo*sin(theta)*dt)
        butaView.center = CGPoint(x: next_x_pos, y: next_y_pos)
        //速度を加速度分変化させる　yが逆なのは，画面の座標はyは下向きが正のため．加速度と反対になっている
        let buta_velo_x1 = buta_velo*cos(theta) + x * g * dt
        let buta_velo_y1 = buta_velo*sin(theta) - y * g * dt
        buta_velo = sqrt(pow(buta_velo_x1, 2)+pow(buta_velo_y1, 2))
        theta = atan2(buta_velo_y1,buta_velo_x1)
        buta_velo = buta_velo + buta_accl * dt
        if buta_velo < 0{
            buta_velo = 0
        }
    }
    
    func startAccelerometers() {
        // Make sure the accelerometer hardware is available.
        if self.motion.isAccelerometerAvailable {
            self.motion.accelerometerUpdateInterval = 0.1
            self.motion.startAccelerometerUpdates()
            
            // Configure a timer to fetch the data. タイマーをつくる
            self.timer = Timer(fire: Date(), interval: dt,
                               repeats: true, block: { (timer) in
                                // Get the accelerometer data.
                                if let data = self.motion.accelerometerData {
                                    let x = data.acceleration.x
                                    let y = data.acceleration.y
                                    ///let z = data.acceleration.z
                                    //だからここで豚ムーブを呼びだす
                                    self.butaMove(x, y)
                                }
            })
            
            // Add the timer to the current run loop. 多分ここでタイマーを起動している
            RunLoop.current.add(self.timer!, forMode: .defaultRunLoopMode)
        }
    }


}

