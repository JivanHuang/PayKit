//
//  PayKit.swift
//  SwiftPayKit
//
//  Created by Jivan on 2022/5/23.
//

import Foundation

public enum PayCode {
    case aliPaySuccess
    case aliPayCancel
    case aliPayFailure

    case wxPaySuccess
    case wxPayCancel
    case wxPayFailure

    case unionPaySuccess
    case unionPayCancel
    case unionPayFailure
}

public typealias PayClosure = (_ success: Bool, _ payCode: PayCode, _ result: [AnyHashable: Any]?) -> Void

public class PayKit: NSObject {
    static let shared = PayKit()
    var closure: PayClosure?
}

public extension PayKit {
    func payOrder<T: PayService>(orderInfo: T, closure: PayClosure? = nil) {
        switch orderInfo.serviceType {
        case .AliPay:
            self.closure = closure
            aliPay(orderInfo: orderInfo)
        case .WXPay:
            self.closure = closure
            wxPayPay(orderInfo: orderInfo)
        case .UnionPay:
            self.closure = closure
            unionPay(orderInfo: orderInfo)
        }
    }
}

private extension PayKit {
    func aliPay<T: PayService>(orderInfo: T) {
        guard let info: AlilPayOrderInfo = orderInfo as? AlilPayOrderInfo else { return }
        AlipaySDK.defaultService().payOrder(info.orderString, fromScheme: info.scheme) { [weak self] result in
            if let status: Int = result?["resultStatus"] as? Int {
                switch status {
                case 9000:
                    if let closure = self?.closure {
                        closure(true, .aliPaySuccess, result)
                    }
                case 6001:
                    if let closure = self?.closure {
                        closure(false, .aliPayCancel, result)
                    }
                default:
                    if let closure = self?.closure {
                        closure(false, .aliPayFailure, result)
                    }
                }
            }
        }
    }

    func wxPayPay<T: PayService>(orderInfo: T) {
        guard let info: WXPayOrderInfo = orderInfo as? WXPayOrderInfo else { return }
        let payReq = PayReq()
        payReq.openID = info.openID
        payReq.partnerId = info.partnerId
        payReq.prepayId = info.prepayId
        payReq.nonceStr = info.nonceStr
        payReq.timeStamp = info.timeStamp
        payReq.package = info.package
        payReq.sign = info.sign
        WXApi.send(payReq) { [weak self] success in
            if let closure = self?.closure {
                let payCode = success ? PayCode.wxPaySuccess : PayCode.wxPayFailure
                closure(success, payCode, [:])
            }
        }
    }

    func unionPay<T: PayService>(orderInfo: T) {
        guard let info: UnionPayOrderInfo = orderInfo as? UnionPayOrderInfo else { return }
        UPPaymentControl.default().startPay(info.orderString, fromScheme: info.scheme, mode: info.mode, viewController: info.viewController)
    }
}

extension PayKit: WXApiDelegate {
    public func onResp(_ resp: BaseResp) {
        if let resp = resp as? PayResp {
            let result: [String: Any] = ["returnKey": resp.returnKey, "errStr": resp.errStr, "errCode": resp.errCode, "type": resp.type]
            switch resp.errCode {
            case 0:
                if let closure = closure {
                    closure(true, .wxPaySuccess, result)
                }
            case -2:
                if let closure = closure {
                    closure(true, .wxPayCancel, result)
                }
            default:
                if let closure = closure {
                    closure(true, .wxPayFailure, result)
                }
            }
        }
    }
}

public extension PayKit {
    func handleOpenURL(url: URL) {
        switch url.scheme {
        case PayScheme.AliPay.rawValue:
            if let host = url.host {
                if host == "safepay" {
                    // 支付宝客户端支付
                    AlipaySDK.defaultService().processOrder(withPaymentResult: url) { [weak self] result in
                        if let code = result?["resultStatus"] as? Int {
                            switch code {
                            case 9000:
                                if let closure = self?.closure {
                                    closure(true, .aliPaySuccess, result)
                                }
                            case 60001:
                                if let closure = self?.closure {
                                    closure(false, .aliPayCancel, result)
                                }
                            default:
                                if let closure = self?.closure {
                                    closure(false, .aliPayFailure, result)
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
                                    closure(true, .aliPaySuccess, result)
                                }
                            case 60001:
                                if let closure = self?.closure {
                                    closure(false, .aliPayCancel, result)
                                }
                            default:
                                if let closure = self?.closure {
                                    closure(false, .aliPayFailure, result)
                                }
                            }
                        }
                    }
                }
            }
        case PayScheme.WXPay.rawValue:
            WXApi.handleOpen(url, delegate: PayKit.shared)
        case PayScheme.UnionPay.rawValue:
            if let host = url.host, host == "uppayresult" || host == "paydemo" {
                UPPaymentControl.default().handlePaymentResult(url) { [weak self] code, data in

                    if let code = code {
                        switch code {
                        case "success":
                            if let closure = self?.closure {
                                closure(true, .unionPaySuccess, data)
                            }
                        case "fail":
                            if let closure = self?.closure {
                                closure(false, .unionPayFailure, data)
                            }
                        case "cancel":
                            if let closure = self?.closure {
                                closure(false, .unionPayCancel, data)
                            }
                        default:
                            if let closure = self?.closure {
                                closure(false, .unionPayFailure, data)
                            }
                        }
                    }
                }
            }
        default:
            break
        }
    }
}
