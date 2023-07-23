import ModernRIBs

public protocol AppHomeDependency: Dependency {
}

final class AppHomeComponent: Component<AppHomeDependency>, TransportHomeDependency {
}

// MARK: - Builder

public protocol AppHomeBuildable: Buildable {
  func build(withListener listener: AppHomeListener) -> ViewableRouting
}

public final class AppHomeBuilder: Builder<AppHomeDependency>, AppHomeBuildable {
  
  public override init(dependency: AppHomeDependency) {
    super.init(dependency: dependency)
  }
  
    
    /// 리블렛에 필요한 객체들을 생성
  public func build(withListener listener: AppHomeListener) -> ViewableRouting {
    let component = AppHomeComponent(dependency: dependency) // 바구니
    let viewController = AppHomeViewController()
    let interactor = AppHomeInteractor(presenter: viewController) // 두뇌
    interactor.listener = listener
    
    let transportHomeBuilder = TransportHomeBuilder(dependency: component)
    
    return AppHomeRouter( // 라우터는 이동을 담당
      interactor: interactor,
      viewController: viewController,
      transportHomeBuildable: transportHomeBuilder
    )
  }
}

// 자식 리불렛을 땟다 붙혔다 하는게 리불렛의 역할
