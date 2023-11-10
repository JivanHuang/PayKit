//
//  PayKit.swift
//  SwiftPayKit
//
//  Created by Jivan on 2022/5/23.
//

import Foundation

public enum PayStatus {
    case success
    case cancel
    case failure
}

public enum PayCode {
    case aliPay(PayStatus)
    case wxPay(PayStatus)
    case unionPay(PayStatus)
    
    var status: PayStatus {
        switch self {
        case .aliPay(let status):
            return status
        case .wxPay(let status):
            return status
        case .unionPay(let status):
            return status
        }
    }
}

public typealias PayClosure = (_ success: Bool, _ payCode: PayCode, _ result: [AnyHashable: Any]?) -> Void

public class PayKit: NSObject {
    static let shared = PayKit()
    var closure: PayClosure?
    
    private lazy var schemes: [String: String] = {
        var schemesDictionary: [String: String] = [:]
        if let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] {
            for urlType in urlTypes {
                if let schemes = urlType["CFBundleURLSchemes"] as? [String], let scheme = schemes.first {
                    if let name = urlType["CFBundleURLName"] as? String {
                        schemesDictionary[scheme] = name
                    }
                }
            }
        }
        return schemes
    }()
    
    public func payOrder<T: PayService>(orderInfo: T, closure: PayClosure? = nil) {
        self.closure = closure
        
        switch orderInfo.serviceType {
        case .aliPay:
            aliPay(orderInfo: orderInfo)
        case .wxPay:
            wxPayPay(orderInfo: orderInfo)
        case .unionPay:
            unionPay(orderInfo: orderInfo)
        }
    }
    
    public func handleOpenURL(url: URL) {
        guard let scheme = url.scheme, let schemeName = schemes[scheme] else { return }
        if schemeName == PayServiceType.aliPay.rawValue {
            if let host = url.host {
                if host == "safepay" {
                    // 支付宝客户端支付
                    AlipaySDK.defaultService().processOrder(withPaymentResult: url) { [weak self] result in
                        if let code = result?["resultStatus"] as? Int {
                            switch code {
                            case 9000:
                                if let closure = self?.closure {
                                    closure(true, .aliPay(.success), result)
                                }
                            case 60001:
                                if let closure = self?.closure {
                                    closure(true, .aliPay(.cancel), result)
                                }
                            default:
                                if let closure = self?.closure {
                                    closure(true, .aliPay(.failure), result)
                                }
                            }
                        }
                    }
                }
                if host == "platformapi" {
                    // 支付宝网页端支付
                    AlipaySDK.defaultService().processAuthResult(url) { [weak self] result in
                        if let code = result?["resultStatus"] as? Int {
                            switch code {
                            case 9000:
                                if let closure = self?.closure {
                                    closure(true, .aliPay(.success), result)
                                }
                            case 60001:
                                if let closure = self?.closure {
                                    closure(true, .aliPay(.cancel), result)
                                }
                            default:
                                if let closure = self?.closure {
                                    closure(true, .aliPay(.failure), result)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if schemeName == PayServiceType.wxPay.rawValue {
            WXApi.handleOpen(url, delegate: PayKit.shared)
        }
        if schemeName == PayServiceType.unionPay.rawValue {
            if let host = url.host, host == "uppayresult" || host == "paydemo" {
                UPPaymentControl.default().handlePaymentResult(url) { [weak self] code, data in
                    
                    if let code = code {
                        switch code {
                        case "success":
                            if let closure = self?.closure {
                                closure(true, .unionPay(.success), data)
                            }
                        case "fail":
                            if let closure = self?.closure {
                                closure(false, .unionPay(.failure), data)
                            }
                        case "cancel":
                            if let closure = self?.closure {
                                closure(false, .unionPay(.cancel), data)
                            }
                        default:
                            if let closure = self?.closure {
                                closure(false, .unionPay(.failure), data)
                            }
                        }
                    }
                }
            }
        }
    }
}

extension PayKit {
    private func aliPay<T: PayService>(orderInfo: T) {
        guard let info = orderInfo as? AlilPayOrderInfo else { return }
        if let key = PayKit.shared.schemes.first(where: { $0.value == info.serviceType.rawValue })?.key as? String {
            AlipaySDK.defaultService().payOrder(info.orderString, fromScheme: key) { [weak self] result in
                if let status = result?["resultStatus"] as? Int {
                    var payCode: PayCode = .aliPay(.failure)
                    switch status {
                    case 9000:
                        payCode = .aliPay(.success)
                    case 6001:
                        payCode = .aliPay(.cancel)
                    default:
                        payCode = .aliPay(.failure)
                    }
                    if let closure = self?.closure {
                        closure(payCode.status == .success, payCode, result)
                    }
                }
            }
        }
    }
    
    private func wxPayPay<T: PayService>(orderInfo: T) {
        guard let info = orderInfo as? WXPayOrderInfo else { return }
        
        let payReq = PayReq()
        payReq.openID = info.openID
        payReq.partnerId = info.partnerId
        payReq.prepayId = info.prepayId
        payReq.nonceStr = info.nonceStr
        payReq.timeStamp = info.timeStamp
        payReq.package = info.package
        payReq.sign = info.sign
        
        WXApi.send(payReq) { [weak self] success in
            let payCode: PayCode = success ? .wxPay(.success) : .wxPay(.failure)
            if let closure = self?.closure {
                closure(success, payCode, [:])
            }
        }
    }
    
    private func unionPay<T: PayService>(orderInfo: T) {
        guard let info = orderInfo as? UnionPayOrderInfo else { return }
        if let key = PayKit.shared.schemes.first(where: { $0.value == info.serviceType.rawValue })?.key as? String {
            UPPaymentControl.default().startPay(info.orderString, fromScheme: key, mode: info.mode, viewController: info.viewController)
        }
    }
    
}

extension PayKit: WXApiDelegate {
    public func onResp(_ resp: BaseResp) {
        if let resp = resp as? PayResp {
            let result: [String: Any] = ["returnKey": resp.returnKey, "errStr": resp.errStr, "errCode": resp.errCode, "type": resp.type]
            switch resp.errCode {
            case 0:
                if let closure = closure {
                    closure(true, .wxPay(.success), result)
                }
            case -2:
                if let closure = closure {
                    closure(true, .wxPay(.cancel), result)
                }
            default:
                if let closure = closure {
                    closure(true, .wxPay(.failure), result)
                }
            }
        }
    }
}
