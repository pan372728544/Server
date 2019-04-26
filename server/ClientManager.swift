//
//  ClientManager.swift
//  Cupid
//
//  Created by panzhijun on 2019/4/19.
//  Copyright © 2019 panzhijun. All rights reserved.
//

import UIKit
import SwiftSocket

protocol ClientManagerDelegate : class {
    
    // 处理群聊
    func sendMsgToClient(_ data : Data)
    func removeClient(_ client : ClientManager)
    
    // 处理单聊
    func sendMsgToClientHandleSingleChat(_ data : Data,fromeId : String,toId : String, chatId : String)
    
    
   
}


class ClientManager: NSObject {
   var tcpClient : TCPClient
    weak var delegate : ClientManagerDelegate?
    
    fileprivate var isClientConnected : Bool = false
    fileprivate var heartTimeCount : Int = 0
    
    

    
    init(tcpClient : TCPClient) {
        self.tcpClient = tcpClient
    }
}

extension ClientManager {
    func startReadMsg(dicClient : inout Dictionary<String,Any>) {
        isClientConnected = true
        
        let timer = Timer(fireAt: Date(), interval: 1, target: self, selector: #selector(checkHeartBeat), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
        timer.fire()
        
        while isClientConnected {
            if let lMsg = tcpClient.read(4) {
                // 1.读取长度的data
                let headData = Data(bytes: lMsg, count: 4)
                var length : Int = 0
                (headData as NSData).getBytes(&length, length: 4)
                
                // 2.读取类型
                guard let typeMsg = tcpClient.read(2) else {
                    return
                }
                let typeData = Data(bytes: typeMsg, count: 2)
                var type : Int = 0
                (typeData as NSData).getBytes(&type, length: 2)
                
                // 3.根据长度, 读取真实消息
                guard let msg = tcpClient.read(length) else {
                    return
                }
                let data = Data(bytes: msg, count: length)
                
                // 完整数据 转发给客户端
                let totalData = headData + typeData + data
                
                // 进入会话
                if type == 0 {
                    // 数据转成聊天数据
                    let chatMsg = try! UserInfo.parseFrom(data: data)
                    // 更新字典数据
                    dicClient.updateValue(tcpClient, forKey: chatMsg.userId)
                    print("\(String(describing: chatMsg.name)) 进入回话页面")
                }
                else if type == 1 {
                    // 离开回话
                    tcpClient.close()
                    delegate?.removeClient(self)
                    // 数据转成聊天数据
                    let chatMsg = try! UserInfo.parseFrom(data: data)
                    // 更新字典数据
                    guard let index = dicClient.index(forKey: chatMsg.userId) else {return}
                    dicClient.remove(at: index)
                    
                    print("\(String(describing: chatMsg.name)) 离开回话页面")
                    
                } else if type == 100 {
                    // 心跳包
                    heartTimeCount = 0
                    continue
                } else if type == 10 {
                    // 获取聊天列表
                    print("获取聊天列表")
                } else if type == 2{
                    
                    // 数据转成聊天数据
                    let chatMsg = try! TextMessage.parseFrom(data: data)
                    // 是否包含这个聊天Id
                    let chatType = chatMsg.chatType
                    // 单聊
                    if chatType == "1" {
                        
                        delegate?.sendMsgToClientHandleSingleChat(totalData, fromeId: chatMsg.user.userId, toId: chatMsg.toUserId,chatId: chatMsg.chatId)
                        continue
                        
                    }
                }
                
                delegate?.sendMsgToClient(totalData)
                
            } else {
                self.removeClient()
            }
        }
    }
    
    @objc fileprivate func checkHeartBeat() {
        heartTimeCount += 1
        if heartTimeCount >= 10 {
            self.removeClient()
        }
    }
    
    private func removeClient() {
        delegate?.removeClient(self)
        isClientConnected = false
        print("客户端断开了连接")
        tcpClient.close()
    }
}
