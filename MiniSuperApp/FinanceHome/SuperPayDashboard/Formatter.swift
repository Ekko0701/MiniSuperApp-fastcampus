//
//  Formatter.swift
//  MiniSuperApp
//
//  Created by Kim Dongjoo on 1/6/26.
//

import Foundation

struct Formatter {
    static let balanceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}
