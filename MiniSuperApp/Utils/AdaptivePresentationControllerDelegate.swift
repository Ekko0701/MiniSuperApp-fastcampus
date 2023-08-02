//
//  AdaptivePresentationControllerDelegate.swift
//  MiniSuperApp
//
//  Created by Kim DongJoo on 2023/08/02.
//

import UIKit

protocol AdaptivePresentationControllerDelegate: AnyObject {
    func presentationControllerDidDismiss()
}

// 이 객체가 UAdaptivable을 대신해서 받아온다.
final class AdaptivePresentationControllerDelegateProxy: NSObject, UIAdaptivePresentationControllerDelegate {
    weak var delegate: AdaptivePresentationControllerDelegate?
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.presentationControllerDidDismiss()
    }
}
