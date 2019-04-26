//
//  ServerManager.swift
//  Cupid
//
//  Created by panzhijun on 2019/4/19.
//  Copyright © 2019 panzhijun. All rights reserved.
//

import UIKit
import SwiftSocket


class ServerManager: NSObject {
    
    // 创建服务器socket
    fileprivate lazy var serverSocket : TCPServer = TCPServer(address: "0.0.0.0", port: 7878)
    // 服务器是否在运行
    fileprivate var isServerRunning : Bool = false
    
    // 客户端数组
    fileprivate lazy var clientMrgs : [ClientManager] = [ClientManager]();

    // 单聊字典
   fileprivate var clientSingleDic : Dictionary = Dictionary<String, Any>()
    
   fileprivate var arrayTemp : Array<Any> = [TCPClient]()

}

extension ServerManager {
    // 开始运行
    @objc public  func startRunning()  {
        // 开启监听
        let res : Result = serverSocket.listen()
        isServerRunning = true
        
        if res.isSuccess {
            print("服务器已经开始监听")
        } else {
            print("服务器开始监听失败---")
        }
        // 开始接受客户端
        DispatchQueue.global().async {
            while self.isServerRunning {
                // 接收客户端数据
                if let client = self.serverSocket.accept() {
                    DispatchQueue.global().async {
                        self.handlerClient(client)
                    }
                }
            }
        }
    }
    
    // 关闭服务器
   @objc func stopRunning() {
        isServerRunning = false
        serverSocket.close()
    }
}

extension ServerManager {
    fileprivate func handlerClient(_ client : TCPClient) {
        // 1.用一个ClientManager管理TCPClient
        let mgr = ClientManager(tcpClient: client)
        mgr.delegate = self
        
        // 2.保存客户端
        clientMrgs.append(mgr)
        
        // 3.用client开始接受消息
        mgr.startReadMsg(dicClient: &clientSingleDic)
    }
}

extension ServerManager : ClientManagerDelegate {
    
    // 群聊
    func sendMsgToClient(_ data: Data) {
        for mgr in clientMrgs {
            _ = mgr.tcpClient.send(data: data)
        }
    }
    
    // 移除客户端
    func removeClient(_ client: ClientManager) {
        guard let index = clientMrgs.index(of: client) else { return }
        clientMrgs.remove(at: index)
    }
    
    // 单聊
    func sendMsgToClientHandleSingleChat(_ data : Data,fromeId : String,toId : String, chatId : String) {
        
        DispatchQueue.main.async {
            // 遍历所有字典
            for (key,_) in self.clientSingleDic {
                
                if (key == fromeId || key == toId) && (chatId == "\(fromeId)_\(toId)" || chatId == "\(toId)_\(fromeId)") {
                    
                    // 判断所在的房间 暂未实现
                    let client : TCPClient = self.clientSingleDic[key] as! TCPClient
                    _ = client.send(data: data)
                }
            }
        }
    }
}
