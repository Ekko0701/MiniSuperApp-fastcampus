//
//  CardOnFileDashboardInteractor.swift
//  MiniSuperApp
//
//  Created by Kim DongJoo on 2023/07/24.
//

import ModernRIBs
import Combine

protocol CardOnFileDashboardRouting: ViewableRouting {
  // TODO: Declare methods the interactor can invoke to manage sub-tree via the router.
}

protocol CardOnFileDashboardPresentable: Presentable {
  var listener: CardOnFileDashboardPresentableListener? { get set }
  // TODO: Declare methods the interactor can invoke the presenter to present data.
  
  func update(with viewModels: [PaymentMethodViewModel])
}

protocol CardOnFileDashboardListener: AnyObject {
  // TODO: Declare methods the interactor can invoke to communicate with other RIBs.
}

protocol CardOnFileDashboardInteractorDependency {
  var cardsOnFileRepository: CardOnFileRepository { get }
}

final class CardOnFileDashboardInteractor: PresentableInteractor<CardOnFileDashboardPresentable>, CardOnFileDashboardInteractable, CardOnFileDashboardPresentableListener {
  
  weak var router: CardOnFileDashboardRouting?
  weak var listener: CardOnFileDashboardListener?
  
  private let dependency: CardOnFileDashboardInteractorDependency
  
  private var cancellables: Set<AnyCancellable>
  
  // TODO: Add additional dependencies to constructor. Do not perform any logic
  // in constructor.
  init(
    presenter: CardOnFileDashboardPresentable,
    dependency: CardOnFileDashboardInteractorDependency
  ) {
    self.dependency = dependency
    self.cancellables = .init()
    super.init(presenter: presenter)
    presenter.listener = self
  }
  
  override func didBecomeActive() {
    super.didBecomeActive()
    // TODO: Implement business logic here.
    
    dependency.cardsOnFileRepository.cardOnFile.sink { method in
      let viewModels = method.prefix(5).map(PaymentMethodViewModel.init)
      self.presenter.update(with: viewModels)
    }.store(in: &cancellables)
  }
  
  override func willResignActive() {
    super.willResignActive()
    cancellables.forEach { $0.cancel() }
    cancellables.removeAll()
  }
}
