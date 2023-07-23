//
//  SuperPayDashboardBuilder.swift
//  MiniSuperApp
//
//  Created by Ekko on 2023/07/23.
//

import ModernRIBs

protocol SuperPayDashboardDependency: Dependency {
  // TODO: Declare the set of dependencies required by this RIB, but cannot be
  // created by this RIB.
  var balance: ReadOnlyCurrentValuePublisher<Double> { get }
}

final class SuperPayDashboardComponent: Component<SuperPayDashboardDependency>, SuperPayDashboardInteractorDependency {
  // TODO: Declare 'fileprivate' dependencies that are only used by this RIB.
  var balance: ReadOnlyCurrentValuePublisher<Double> { dependency.balance } // dependency로 부터 전달하는 역할만 해주자.
}

// MARK: - Builder

protocol SuperPayDashboardBuildable: Buildable {
  func build(withListener listener: SuperPayDashboardListener) -> SuperPayDashboardRouting
}

final class SuperPayDashboardBuilder: Builder<SuperPayDashboardDependency>, SuperPayDashboardBuildable {
  
  override init(dependency: SuperPayDashboardDependency) {
    super.init(dependency: dependency)
  }
  
  func build(withListener listener: SuperPayDashboardListener) -> SuperPayDashboardRouting {
    let component = SuperPayDashboardComponent(dependency: dependency)
    let viewController = SuperPayDashboardViewController()
    let interactor = SuperPayDashboardInteractor(
      presenter: viewController,
      dependency: component
    )
    interactor.listener = listener
    return SuperPayDashboardRouter(interactor: interactor, viewController: viewController)
  }
}
