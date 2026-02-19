//
//  AdaptivePresentationControllerDelegate.swift
//  MiniSuperApp
//
//  Created by Kim Dongjoo on 2/18/26.
//

import UIKit

protocol AdaptivePresentationControllerDelegate: AnyObject {
    func presentationControllerDidDismiss()
}

final class AdaptivePresentationControllerDelegateProxy: NSObject, UIAdaptivePresentationControllerDelegate {
    weak var delegate: AdaptivePresentationControllerDelegate?
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.presentationControllerDidDismiss()
    }
}
