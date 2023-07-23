//
//  SuperPayDashboardViewController.swift
//  MiniSuperApp
//
//  Created by Ekko on 2023/07/23.
//

import ModernRIBs
import UIKit

protocol SuperPayDashboardPresentableListener: AnyObject {
    // TODO: Declare properties and methods that the view controller can invoke to perform
    // business logic, such as signIn(). This protocol is implemented by the corresponding
    // interactor class.
}

final class SuperPayDashboardViewController: UIViewController, SuperPayDashboardPresentable, SuperPayDashboardViewControllable {

  weak var listener: SuperPayDashboardPresentableListener?
  
  private let headerStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.alignment = .fill
    stackView.distribution = .equalSpacing
    stackView.axis = . horizontal
    return stackView
  }()
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 22, weight: .bold)
    label.text = "슈퍼페이 잔고"
    return label
  }()
  
  private lazy var topupButton: UIButton = { // target에는 self가 들어가게 되는데, ViewController가 생성된 다음에 불려야 하기 때문에 lazy var 으로 선언하자
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle("충전하기", for: .normal)
    button.setTitleColor(.systemBlue, for: .normal)
    button.addTarget(self, action: #selector(topupButtonDidTap), for: .touchUpInside)
    return button
  }()
  
  private let cardView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer.cornerRadius = 15
    view.layer.cornerCurve = .continuous // Corner의 곡선이 부드럽게 표현
    view.backgroundColor = .systemIndigo
    return view
  }()
  
  private let currencyLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 22, weight: .semibold)
    label.text = "원"
    label.textColor = .white
    return label
  }()
  
  private let balanceAmountLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 22, weight: .semibold)
    label.textColor = .white
    label.text = " 1,000,000,000"
    return label
  }()
  
  private let balanceStackView: UIStackView = {
    let stack = UIStackView()
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.alignment = .fill
    stack.distribution = .equalSpacing
    stack.axis = .horizontal
    stack.spacing = 4
    return stack
  }()
  
  init() {
    super.init(nibName: nil, bundle: nil)
    setupViews()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupViews()
  }
  
  private func setupViews() {
    view.addSubview(headerStackView)
    view.addSubview(cardView)
    
    headerStackView.addArrangedSubview(titleLabel)
    headerStackView.addArrangedSubview(topupButton)
    
    cardView.addSubview(balanceStackView)
    
    balanceStackView.addArrangedSubview(balanceAmountLabel)
    balanceStackView.addArrangedSubview(currencyLabel)
    
    NSLayoutConstraint.activate([
      headerStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
      headerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      headerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      
      cardView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 10),
      cardView.heightAnchor.constraint(equalToConstant: 180),
      cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
      
      balanceStackView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
      balanceStackView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
    ])
  }
  
  func updateBalance(_ balance: String) {
    balanceAmountLabel.text = balance
  }
  
  @objc
  private func topupButtonDidTap() { }
}
