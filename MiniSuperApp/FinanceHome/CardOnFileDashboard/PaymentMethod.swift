//
//  PaymentMethod.swift
//  MiniSuperApp
//
//  Created by Kim DongJoo on 2023/07/24.
//

import Foundation

/// Backend에서 받는 모델이라고 가정
struct PaymentMethod: Decodable {
  let id: String
  let name: String
  let digits: String
  let color: String
  let isPrimary: Bool
}
