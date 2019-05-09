//
//  RealmTool.swift
//  Cupid
//
//  Created by panzhijun on 2019/4/28.
//  Copyright © 2019 panzhijun. All rights reserved.
//

import UIKit
import RealmSwift

class RealmTool: Object {
    private class func defaultRealm() -> Realm {
        /// 传入路径会自动创建数据库
        let defaultRealm = try! Realm(fileURL: URL.init(string: getRealmPath())!)
        return defaultRealm
    }
}

extension RealmTool {
    
    private class func getRealmPath() -> String{
        let docPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as String
        
        var name : String = "common"
        let dbPath = docPath.appending("/\(name).realm")
        print("realm地址为： \(dbPath)")
        return dbPath
    }
}

// MARK: - 配置
extension RealmTool  {

    @objc  public class func configRealm() {

//        var config = Realm.Configuration()
        // 设置路径 配置一
//        config.fileURL = URL.init(string: getRealmPath())
//        Realm.Configuration.defaultConfiguration = config
        
        // 配置二 数据库迁移 （数据库发生变化版本号也要变化）
        let currentVersion = 1
        
        let config = Realm.Configuration(fileURL: URL.init(string: getRealmPath()), inMemoryIdentifier: nil, syncConfiguration: nil, encryptionKey: nil, readOnly: false, schemaVersion: UInt64(currentVersion), migrationBlock: { (migration, oldVersion) in

            migration.enumerateObjects(ofType: ChatMessage.className(), { (OldMigrationObject, NewMigrationObject) in
                // 数据库迁移操作
//                let name =  OldMigrationObject["name"]
//                NewMigrationObject["aaa"] = name
            })

            print("")
            
        }, deleteRealmIfMigrationNeeded: false, shouldCompactOnLaunch: nil, objectTypes: nil)
        Realm.Configuration.defaultConfiguration = config
        
        // 异步打开数据库
        Realm.asyncOpen { (realm, error) in
            if let _ = realm {
                print("Realm 服务器配置成功!")
            }else if let error = error {
                print("Realm 数据库配置失败：\(error.localizedDescription)")
            }
        }
    }
}

// MARK: - 数据库操作 增加数据
extension RealmTool {
    /// 保存一个ChatMessage
    public class func insertMessage(by message : ChatMessage) {
        let realm = self.defaultRealm()
        try! realm.write {
            realm.add(message)
        }
    }
    

}

// MARK: - 数据库操作 查找
extension RealmTool {
    /// 获取 所保存的 ChatMessage
    public class func getMessages() -> Results<ChatMessage> {
        let realm = self.defaultRealm()
        return realm.objects(ChatMessage.self)
    }
    
    
    /// 获取 指定条件查询
    public class func getMessageByPredicate(_ predicate: String) -> Results<ChatMessage> {
        let realm = self.defaultRealm()
        
        let pre = NSPredicate(format: predicate)
        let results = realm.objects(ChatMessage.self)
        return  results.filter(pre)
    }
    
    
}



// MARK: - 数据库操作 删除
extension RealmTool {

    /// 删除多个 ChatMessage
    public class func deleteMessages(messages : Results<ChatMessage>) {
        let realm = self.defaultRealm()
        try! realm.write {
            realm.delete(messages)
        }
    }
    

}



