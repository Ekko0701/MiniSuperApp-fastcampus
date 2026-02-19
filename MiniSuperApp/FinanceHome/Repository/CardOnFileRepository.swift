//
//  CardOnFileRepository.swift
//  MiniSuperApp
//
//  Created by Kim Dongjoo on 1/7/26.
//

import Foundation
import Combine

protocol CardOnFileRepository {
    var cardOnFile: ReadOnlyCurrentValuePublisher<[PaymentMethod]> { get }
    func addCard(info: AddPaymentMethodInfo) -> AnyPublisher<PaymentMethod, Error>
}

final class CardOnFileRepositoryImp: CardOnFileRepository {
    public var cardOnFile: ReadOnlyCurrentValuePublisher<[PaymentMethod]> { paymentMethodsSubject }
    
    private let paymentMethodsSubject = CurrentValuePublisher<[PaymentMethod]>([
        PaymentMethod(id: "0", name: "우리은행", digits: "0123", color: "#f19a38ff", isPrimary: false),
        PaymentMethod(id: "1", name: "신한카드", digits: "0987", color: "#3478f6ff", isPrimary: false),
        PaymentMethod(id: "2", name: "현대카드", digits: "8121", color: "#78c5f5ff", isPrimary: false),
    ])
    
    func addCard(info: AddPaymentMethodInfo) -> AnyPublisher<PaymentMethod, any Error> {
        let paymentMethod = PaymentMethod(id: "00", name: "New 카드", digits: "\(info.number.suffix(4))", color: "", isPrimary: false)
        
        var new = paymentMethodsSubject.value
        new.append(paymentMethod)
        paymentMethodsSubject.send(new)
        
        return Just(paymentMethod).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
