//
//  NumberFormatter.swift
//  MiniSuperApp
//
//  Created by Kim DongJoo on 2023/07/24.
//

import Foundation

struct Formatter {
    static let balanceFormatter: NumberFormatter = {
       let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}
