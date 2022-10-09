//
//  PayOrderInfo.swift
//  SwiftPayKit
//
//  Created by Jivan on 2022/5/23.
//

import Foundation

public enum PayServiceType {
    case AliPay
    case WXPay
    case UnionPay
}

public enum PayScheme: String {
    case AliPayScheme = "AliPayScheme..."
    case WXPayScheme = "WXPayScheme..."
    case UnionPayScheme = "UnionPayScheme..."
}

public protocol PayService {
    var serviceType: PayServiceType { get }
}

public struct AlilPayOrderInfo: PayService {
    /// 服务类型
    public var serviceType: PayServiceType = .AliPay
    /// 用于支付结果回调
    var scheme: String = PayScheme.AliPayScheme.rawValue
    /// 向服务获取的经过签名加密的订单字符串
    var orderString: String
}

public struct WXPayOrderInfo: PayService {
    /// 服务类型
    public var serviceType: PayServiceType = .WXPay
    /// 由用户微信号和AppID组成的唯一标识，发送请求时第三方程序必须填写，用于校验微信用户是否换号登录
    var openID: String
    /// 商家向财付通申请的商家id
    var partnerId: String
    /// 预支付订单
    var prepayId: String
    /// 随机串，防重发
    var nonceStr: String
    /// 时间戳，防重发
    var timeStamp: UInt32
    /// 商家根据财付通文档填写的数据和签名
    var package: String
    /// 商家根据微信开放平台文档对数据做的签名
    var sign: String
}

public struct UnionPayOrderInfo: PayService {
    /// 服务类型
    public var serviceType: PayServiceType = .UnionPay
    /// 支付环境   01:测试环境 00:生产环境
    var mode: String
    /// 用于支付结果回调
    var scheme: String = PayScheme.UnionPayScheme.rawValue
    /// 向服务获取的经过签名加密的订单字符串
    var orderString: String
    /// 启动支付控件的viewController
    var viewController: UIViewController
}
