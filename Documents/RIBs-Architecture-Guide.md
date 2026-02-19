# RIBs 아키텍처 완벽 가이드

> 이 문서는 MiniSuperApp 프로젝트의 실제 코드를 기반으로 RIBs 아키텍처를 설명합니다.
> 주니어 개발자도 이해할 수 있도록 모든 개념을 단계별로 풀어서 설명합니다.
>
> - **작성자**: Ekko0701
> - **작성일**: 2026-02-15
> - **프로젝트**: MiniSuperApp-fastcampus
> - **라이브러리**: [ModernRIBs](https://github.com/DevYeom/ModernRIBs) 1.0.1

---

## 목차

1. [RIBs란 무엇인가?](#1-ribs란-무엇인가)
2. [왜 RIBs를 사용하는가?](#2-왜-ribs를-사용하는가)
3. [RIB의 구성 요소 5가지](#3-rib의-구성-요소-5가지)
4. [프로토콜 패턴 상세 해부](#4-프로토콜-패턴-상세-해부)
5. [RIB 트리: 부모와 자식의 관계](#5-rib-트리-부모와-자식의-관계)
6. [데이터 흐름: 의존성 주입과 Listener](#6-데이터-흐름-의존성-주입과-listener)
7. [생명주기: attach와 detach](#7-생명주기-attach와-detach)
8. [실제 코드로 따라가기: FinanceHome RIB](#8-실제-코드로-따라가기-financehome-rib)
9. [앱 전체 흐름: AppDelegate에서 화면까지](#9-앱-전체-흐름-appdelegate에서-화면까지)
10. [자주 하는 실수와 주의사항](#10-자주-하는-실수와-주의사항)
11. [용어 정리](#11-용어-정리)

---

## 1. RIBs란 무엇인가?

### 한 줄 요약

**RIBs**는 Uber가 만든 모바일 아키텍처 프레임워크로, 앱을 **작은 독립적인 조각(RIB)**으로 나누어 개발하는 방식입니다.

### 이름의 의미

**R**outer + **I**nteractor + **B**uilder = **RIBs**

이 세 가지가 RIB의 핵심 구성 요소이며, 여기에 ViewController(View)와 Component가 추가됩니다.

### 쉬운 비유

레고 블록을 생각해보세요:

- 각 **레고 블록** = 하나의 **RIB** (독립적인 기능 단위)
- 블록끼리 **끼우는 방법** = **Router** (어떤 블록을 붙일지 관리)
- 블록 안의 **회로** = **Interactor** (실제 동작하는 로직)
- 블록의 **설명서** = **Builder** (블록을 어떻게 조립하는지)
- 블록의 **겉모습** = **ViewController** (사용자가 보는 화면)

```
┌─────────────────────────────────────────┐
│                하나의 RIB                 │
│                                         │
│  ┌──────────┐  ┌────────────────────┐   │
│  │ Builder  │  │    Interactor      │   │
│  │ (조립)    │→│    (비즈니스 로직)    │   │
│  └──────────┘  └────────┬───────────┘   │
│                         │               │
│  ┌──────────┐  ┌────────▼───────────┐   │
│  │Component │  │     Router         │   │
│  │(의존성)   │  │  (자식 RIB 관리)    │   │
│  └──────────┘  └────────┬───────────┘   │
│                         │               │
│                ┌────────▼───────────┐   │
│                │  ViewController    │   │
│                │  (화면 표시)        │   │
│                └────────────────────┘   │
└─────────────────────────────────────────┘
```

---

## 2. 왜 RIBs를 사용하는가?

### MVC/MVVM과의 차이

| 비교 항목 | MVC / MVVM | RIBs |
|-----------|-----------|------|
| **중심** | ViewController (화면 중심) | Interactor (비즈니스 로직 중심) |
| **화면 전환** | ViewController가 직접 관리 | Router가 전담 관리 |
| **의존성** | 직접 생성하거나 싱글톤 | Builder/Component로 명시적 주입 |
| **테스트** | UI와 로직이 섞여 테스트 어려움 | 각 요소를 독립적으로 테스트 가능 |
| **협업** | 한 파일에 코드 집중 → 충돌 빈번 | 역할별 파일 분리 → 충돌 최소화 |

### RIBs의 핵심 장점

1. **비즈니스 로직 중심**: 화면이 없는 RIB도 가능합니다. (로그인 상태 관리 같은 보이지 않는 로직)
2. **명확한 역할 분리**: "이 코드 어디에 넣지?"라는 고민이 사라집니다.
3. **의존성 명시화**: 각 RIB이 필요한 것을 프로토콜로 선언하므로, 빠진 의존성을 컴파일 타임에 잡을 수 있습니다.
4. **트리 구조**: 앱의 상태를 RIB 트리로 표현할 수 있어 디버깅이 쉽습니다.

---

## 3. RIB의 구성 요소 5가지

하나의 RIB은 보통 **4~5개의 파일**로 구성됩니다. 이 프로젝트의 `FinanceHome` RIB을 예로 들어 설명합니다.

### 3.1 Builder — 조립 담당

> **역할**: RIB을 구성하는 모든 객체를 생성하고 조립합니다.
> **비유**: 레고 설명서. "이 블록은 이렇게 조립하세요"

```
📁 FinanceHomeBuilder.swift
```

```swift
// Builder는 RIB의 모든 구성 요소를 만들어서 연결합니다
final class FinanceHomeBuilder: Builder<FinanceHomeDependency>, FinanceHomeBuildable {

    func build(withListener listener: FinanceHomeListener) -> FinanceHomeRouting {
        // 1. Component 생성 (의존성 모음)
        let component = FinanceHomeComponent(
            dependency: dependency,
            balance: balancePublisher,
            cardOnFileRepository: CardOnFileRepositoryImp()
        )

        // 2. ViewController 생성 (화면)
        let viewController = FinanceHomeViewController()

        // 3. Interactor 생성 (비즈니스 로직)
        let interactor = FinanceHomeInteractor(presenter: viewController)
        interactor.listener = listener  // 부모와의 통신 연결

        // 4. 자식 Builder 생성
        let superPayDashboardBuilder = SuperPayDashboardBuilder(dependency: component)
        let cardOnFileDashboardBuilder = CardOnFileDashboardBuilder(dependency: component)

        // 5. Router 생성 후 반환 (모든 것을 묶어서)
        return FinanceHomeRouter(
            interactor: interactor,
            viewController: viewController,
            superPayDashboardBuildable: superPayDashboardBuilder,
            cardOnFileDashboardBuildable: cardOnFileDashboardBuilder
        )
    }
}
```

**핵심 포인트**:
- Builder의 `build()` 메서드가 호출되면, RIB의 모든 구성 요소가 생성됩니다.
- `listener` 파라미터를 통해 부모 RIB과의 통신 채널을 연결합니다.
- 최종 반환값은 **Router**입니다 (부모가 Router를 통해 자식을 관리하므로).

---

### 3.2 Interactor — 두뇌 (비즈니스 로직)

> **역할**: RIB의 모든 비즈니스 로직을 담당합니다. "무엇을 할 것인가"를 결정합니다.
> **비유**: 사령관. 판단하고 명령을 내리지만, 직접 화면을 그리거나 이동하지는 않습니다.

```
📁 FinanceHomeInteractor.swift
```

```swift
final class FinanceHomeInteractor: PresentableInteractor<FinanceHomePresentable>,
    FinanceHomeInteractable, FinanceHomePresentableListener {

    weak var router: FinanceHomeRouting?    // Router에게 화면 전환 요청
    weak var listener: FinanceHomeListener? // 부모 RIB에게 이벤트 전달

    override func didBecomeActive() {
        super.didBecomeActive()

        // RIB이 활성화되면 자식 대시보드들을 붙인다
        router?.attachSuperPayDashboard()
        router?.attachCardOnFileDashboard()
    }

    override func willResignActive() {
        super.willResignActive()
        // RIB이 비활성화될 때 정리 작업
    }
}
```

**핵심 포인트**:
- `router`를 통해 화면 전환을 **요청**합니다 (직접 하지 않음).
- `listener`를 통해 부모 RIB에게 이벤트를 **알립니다**.
- `didBecomeActive()` / `willResignActive()`가 생명주기 메서드입니다.
- **UIKit을 절대 import하지 않습니다** — UI와 완전히 분리됩니다.

---

### 3.3 Router — 내비게이션 담당

> **역할**: 자식 RIB을 붙이고(attach) 떼는(detach) 역할. 화면 전환의 실제 실행자입니다.
> **비유**: 교통 경찰. "이 화면 보여줘", "이 화면 치워줘"를 실행합니다.

```
📁 FinanceHomeRouter.swift
```

```swift
final class FinanceHomeRouter: ViewableRouter<FinanceHomeInteractable, FinanceHomeViewControllable>,
    FinanceHomeRouting {

    // 자식 RIB의 Builder (주입받음)
    private let superPayDashboardBuildable: SuperPayDashboardBuildable
    private var superPayingRouting: Routing?  // 현재 붙어있는 자식 Router 참조

    private let cardOnFileDashboardBuildable: CardOnFileDashboardBuildable
    private var cardOnFileRouting: Routing?

    // 자식 RIB을 붙이는 메서드
    func attachSuperPayDashboard() {
        if superPayingRouting != nil {
            return  // 이미 붙어있으면 무시 (중복 방지)
        }

        // 1. Builder로 자식 RIB을 생성
        let router = superPayDashboardBuildable.build(withListener: interactor)

        // 2. 자식의 ViewController를 부모 화면에 추가
        let dashboard = router.viewControllable
        viewController.addDashboard(dashboard)

        // 3. 참조 저장 + RIB 트리에 연결
        self.superPayingRouting = router
        attachChild(router)
    }
}
```

**핵심 포인트**:
- `attachChild(router)` — 자식 RIB을 트리에 연결합니다 (생명주기 시작).
- `detachChild(router)` — 자식 RIB을 트리에서 분리합니다 (생명주기 종료).
- 중복 attach를 방지하기 위해 `if routing != nil { return }` 가드가 필수입니다.
- Builder**Buildable** (프로토콜)을 주입받아 구체 타입에 의존하지 않습니다.

---

### 3.4 ViewController — 화면 표시

> **역할**: 사용자에게 보여지는 UI를 담당합니다. 사용자 입력을 받아 Interactor에 전달합니다.
> **비유**: 배우. 대본(Interactor의 지시)에 따라 연기(화면 표시)합니다.

```
📁 FinanceHomeViewController.swift
```

```swift
final class FinanceHomeViewController: UIViewController,
    FinanceHomePresentable, FinanceHomeViewControllable {

    weak var listener: FinanceHomePresentableListener?  // Interactor에게 이벤트 전달

    // 자식 RIB의 화면을 추가하는 메서드
    func addDashboard(_ view: ViewControllable) {
        let vc = view.uiviewController

        addChild(vc)                              // UIKit 부모-자식 관계
        stackView.addArrangedSubview(vc.view)     // 화면에 추가
        vc.didMove(toParent: self)                // UIKit 생명주기 알림
    }
}
```

**핵심 포인트**:
- `FinanceHomePresentable` — Interactor가 ViewController에게 데이터를 전달할 때 사용하는 프로토콜
- `FinanceHomeViewControllable` — Router가 ViewController에게 화면 조작을 요청할 때 사용하는 프로토콜
- `listener`를 통해 사용자 액션을 Interactor에 전달합니다
- **비즈니스 로직을 절대 포함하지 않습니다** — 오직 화면 그리기와 사용자 입력 전달만

---

### 3.5 Component — 의존성 컨테이너

> **역할**: RIB이 필요로 하는 의존성(데이터, 서비스 등)을 모아두는 곳입니다.
> **비유**: 도구 상자. 이 RIB과 자식 RIB이 사용할 도구를 담아둡니다.

```swift
// FinanceHomeBuilder.swift 내부에 정의
final class FinanceHomeComponent: Component<FinanceHomeDependency>,
    SuperPayDashboardDependency, CardOnFileDashboardDependency {

    let cardOnFileRepository: CardOnFileRepository
    var balance: ReadOnlyCurrentValuePublisher<Double> { balancePublisher }
    private let balancePublisher: CurrentValuePublisher<Double>
}
```

**핵심 포인트**:
- `Component<FinanceHomeDependency>` — 부모로부터 받은 의존성에 접근
- `SuperPayDashboardDependency` 프로토콜 준수 — 자식 RIB에게 필요한 의존성 제공
- 부모에게 받은 것 + 자체적으로 생성한 것을 합쳐서 자식에게 전달합니다

---

## 4. 프로토콜 패턴 상세 해부

RIBs에서 가장 혼란스러운 부분이 **수많은 프로토콜**입니다. 하나씩 정리하겠습니다.

### 4.1 프로토콜 전체 지도

하나의 RIB(`FinanceHome`)에 등장하는 프로토콜을 모두 모아보면:

```
┌─ Builder 파일 ────────────────────────────────────────┐
│                                                       │
│  FinanceHomeDependency   ← 부모에게 "이것 필요해요"     │
│  FinanceHomeComponent    ← 의존성 모음 (구현체)         │
│  FinanceHomeBuildable    ← "나를 이렇게 만들어주세요"    │
│  FinanceHomeBuilder      ← 실제 조립 (구현체)          │
│                                                       │
├─ Interactor 파일 ─────────────────────────────────────┤
│                                                       │
│  FinanceHomeRouting      ← Router에게 "이것 해줘"      │
│  FinanceHomePresentable  ← VC에게 "이것 보여줘"         │
│  FinanceHomeListener     ← 부모에게 "이런 일 생겼어요"  │
│  FinanceHomeInteractor   ← 비즈니스 로직 (구현체)       │
│                                                       │
├─ Router 파일 ─────────────────────────────────────────┤
│                                                       │
│  FinanceHomeInteractable ← Interactor 통합 인터페이스   │
│  FinanceHomeViewControllable ← VC에게 "화면 조작해줘"   │
│  FinanceHomeRouter       ← 내비게이션 (구현체)          │
│                                                       │
├─ ViewController 파일 ─────────────────────────────────┤
│                                                       │
│  FinanceHomePresentableListener ← Interactor에게 전달  │
│  FinanceHomeViewController     ← 화면 (구현체)         │
│                                                       │
└───────────────────────────────────────────────────────┘
```

### 4.2 프로토콜 간의 관계도

```
                     FinanceHomeListener
                     (부모 RIB ← Interactor)
                            ▲
                            │ 이벤트 전파
                            │
                     ┌──────┴──────┐
                     │  Interactor  │
                     │             │
      요청          │  FinanceHome │          지시
  ┌────────────────│  Interactable│────────────────┐
  │                │             │                │
  ▼                └──────┬──────┘                ▼
┌──────────┐              │              ┌────────────────┐
│  Router  │              │              │ ViewController │
│          │◄─────────────┘              │                │
│ Routing  │     FinanceHomeRouting      │  Presentable   │
│          │     (Interactor→Router)     │                │
└──────────┘                             └───────┬────────┘
                                                 │
                                    PresentableListener
                                    (VC → Interactor)
```

### 4.3 각 프로토콜의 역할 요약

| 프로토콜 | 정의 위치 | 누가 준수 | 누가 사용 | 역할 |
|---------|----------|---------|---------|------|
| `Dependency` | Builder | 부모 Component | Builder | 부모에게 필요한 의존성 선언 |
| `Buildable` | Builder | Builder | 부모 Router | RIB 생성 인터페이스 |
| `Routing` | Interactor | Router | Interactor | 화면 전환 요청 |
| `Presentable` | Interactor | ViewController | Interactor | 데이터 표시 요청 |
| `Listener` | Interactor | 부모 Interactor | Interactor | 부모에게 이벤트 전달 |
| `Interactable` | Router | Interactor | Router | 자식 Listener 통합 |
| `ViewControllable` | Router | ViewController | Router | 화면 조작 요청 |
| `PresentableListener` | ViewController | Interactor | ViewController | 사용자 입력 전달 |

---

## 5. RIB 트리: 부모와 자식의 관계

### MiniSuperApp의 RIB 트리

이 프로젝트의 전체 RIB 트리는 다음과 같습니다:

```
AppRoot (루트 RIB)
│
├── AppHome (홈 탭)
│   └── 위젯 표시
│
├── FinanceHome (슈퍼페이 탭) ─── 이 문서에서 집중적으로 다루는 부분
│   ├── SuperPayDashboard (잔고 대시보드)
│   └── CardOnFileDashboard (카드/계좌 목록)
│
├── TransportHome (교통 탭)
│   └── 택시 호출 UI
│
└── ProfileHome (프로필 탭)
    └── 사용자 정보
```

### 트리의 의미

- **부모 RIB**은 **자식 RIB**을 attach/detach할 수 있습니다.
- 자식은 부모를 직접 알지 못합니다. 오직 **Listener 프로토콜**을 통해서만 소통합니다.
- 형제 RIB끼리는 직접 소통할 수 **없습니다**. 반드시 공통 부모를 경유해야 합니다.

```
         FinanceHome (부모)
         /          \
        /            \
   SuperPay    CardOnFile    ← 형제 RIB
   Dashboard   Dashboard
   
   ✅ SuperPay → FinanceHome → CardOnFile  (부모를 통한 간접 통신)
   ❌ SuperPay → CardOnFile               (직접 통신 금지!)
```

---

## 6. 데이터 흐름: 의존성 주입과 Listener

### 6.1 하향 흐름 — 의존성 주입 (부모 → 자식)

데이터가 **부모에서 자식으로** 흐를 때는 **Dependency + Component** 패턴을 사용합니다.

```
[FinanceHome]                         [SuperPayDashboard]
                                      
FinanceHomeComponent ──────────────→ SuperPayDashboardDependency
   balance (잔고 데이터)                  var balance 필요해요!
   cardOnFileRepository                
```

실제 코드:

```swift
// 1단계: 자식이 "이것 필요해요"라고 선언
protocol SuperPayDashboardDependency: Dependency {
    var balance: ReadOnlyCurrentValuePublisher<Double> { get }
}

// 2단계: 부모의 Component가 "내가 줄게"라고 준수
final class FinanceHomeComponent: Component<FinanceHomeDependency>,
    SuperPayDashboardDependency {  // ← 자식의 Dependency를 준수!

    var balance: ReadOnlyCurrentValuePublisher<Double> { balancePublisher }
}

// 3단계: Builder에서 Component를 자식 Builder에게 전달
let superPayDashboardBuilder = SuperPayDashboardBuilder(dependency: component)
//                                                       ^^^^^^^^^ Component 전달
```

**흐름 정리**:
```
부모 Component ──(Dependency 프로토콜)──→ 자식 Builder ──→ 자식 Component ──→ 자식 Interactor
```

### 6.2 상향 흐름 — Listener (자식 → 부모)

데이터가 **자식에서 부모로** 흐를 때는 **Listener** 프로토콜을 사용합니다.

`TransportHome` RIB에서 뒤로가기를 누르면, 부모에게 알려야 합니다:

```swift
// 1단계: 자식이 Listener 프로토콜 정의 (어떤 이벤트를 보낼 수 있는지)
protocol TransportHomeListener: AnyObject {
    func transportHomeDidTapClose()
}

// 2단계: 자식 Interactor에서 Listener를 통해 이벤트 전달
final class TransportHomeInteractor: ... {
    weak var listener: TransportHomeListener?

    func didTapBack() {
        listener?.transportHomeDidTapClose()  // 부모에게 "닫기 눌렀어요!"
    }
}

// 3단계: 부모 Interactor가 Listener를 준수하여 처리
// (부모의 Interactable이 TransportHomeListener를 채택)
```

**흐름 정리**:
```
자식 VC ──(PresentableListener)──→ 자식 Interactor ──(Listener)──→ 부모 Interactor
```

### 6.3 전체 데이터 흐름 다이어그램

```
                    Dependency (의존성 주입)
                    ─────────────────────→
                    
    ┌──────────┐                          ┌──────────┐
    │  부모     │                          │  자식     │
    │  RIB     │                          │  RIB     │
    │          │    Listener (이벤트)       │          │
    │          │ ←─────────────────────    │          │
    └──────────┘                          └──────────┘
    
    ※ 하향: Component → Dependency (컴파일 타임 보장)
    ※ 상향: Listener 프로토콜 (런타임 weak 참조)
```

---

## 7. 생명주기: attach와 detach

### 7.1 RIB의 생명주기

```
        ┌──────────────────────────────────────┐
        │                                      │
        │     build()                          │
        │        │                             │
        │        ▼                             │
        │   attachChild(router)                │
        │        │                             │
        │        ▼                             │
        │   didBecomeActive()  ← 여기서 시작!   │
        │        │                             │
        │        │  (RIB이 살아있는 동안)        │
        │        │  - 데이터 구독               │
        │        │  - 사용자 이벤트 처리         │
        │        │  - 자식 RIB attach          │
        │        │                             │
        │        ▼                             │
        │   willResignActive() ← 여기서 정리!   │
        │        │                             │
        │        ▼                             │
        │   detachChild(router)                │
        │                                      │
        └──────────────────────────────────────┘
```

### 7.2 실제 예시: SuperPayDashboard의 생명주기

```swift
// SuperPayDashboardInteractor.swift

override func didBecomeActive() {
    super.didBecomeActive()

    // RIB이 활성화되면 잔고 데이터를 구독합니다
    dependency.balance.sink { [weak self] balance in
        self?.dependency.balanceFormatter
            .string(from: NSNumber(value: balance))
            .map { self?.presenter.updateBalance($0) }
    }.store(in: &cancellables)
}

override func willResignActive() {
    super.willResignActive()

    // RIB이 비활성화되면 구독을 해제합니다
    cancellables.forEach { $0.cancel() }
    cancellables.removeAll()
}
```

### 7.3 attach/detach 패턴

Router에서 자식 RIB을 관리하는 표준 패턴:

```swift
// FinanceHomeRouter.swift

// ✅ attach: 자식 RIB 연결
func attachSuperPayDashboard() {
    // 1. 이미 붙어있으면 무시 (중복 방지!)
    if superPayingRouting != nil {
        return
    }

    // 2. Builder로 자식 RIB 생성
    let router = superPayDashboardBuildable.build(withListener: interactor)

    // 3. 화면에 자식 ViewController 추가
    let dashboard = router.viewControllable
    viewController.addDashboard(dashboard)

    // 4. 참조 저장 + RIB 트리에 연결
    self.superPayingRouting = router
    attachChild(router)  // → 자식의 didBecomeActive() 호출됨
}

// ✅ detach: 자식 RIB 분리 (이 프로젝트에서는 아직 미구현)
func detachSuperPayDashboard() {
    guard let router = superPayingRouting else { return }
    
    detachChild(router)  // → 자식의 willResignActive() 호출됨
    self.superPayingRouting = nil
}
```

---

## 8. 실제 코드로 따라가기: FinanceHome RIB

`FinanceHome` RIB의 전체 흐름을 처음부터 끝까지 따라가 봅시다.

### Step 1: 부모(AppRoot)가 FinanceHome을 생성

```swift
// AppRootBuilder.swift
func build() -> (launchRouter: LaunchRouting, urlHandler: URLHandler) {
    let component = AppRootComponent(dependency: dependency)
    let financeHome = FinanceHomeBuilder(dependency: component)
    //                                   ^^^^^^^^^ AppRootComponent를 의존성으로 전달
    let router = AppRootRouter(
        interactor: interactor,
        viewController: tabBar,
        financeHome: financeHome,  // Builder를 Router에 주입
        ...
    )
    return (router, interactor)
}
```

### Step 2: AppRootRouter가 FinanceHome RIB을 attach

```
AppRootRouter.attachFinanceHome()
    │
    ├── financeHome.build(withListener: interactor)
    │       │
    │       ├── FinanceHomeComponent 생성
    │       ├── FinanceHomeViewController 생성
    │       ├── FinanceHomeInteractor 생성 (presenter = VC)
    │       ├── interactor.listener = listener (AppRoot과 연결)
    │       ├── SuperPayDashboardBuilder 생성
    │       ├── CardOnFileDashboardBuilder 생성
    │       └── FinanceHomeRouter 생성 (모든 것을 묶음)
    │
    └── attachChild(financeHomeRouter)
            → FinanceHomeInteractor.didBecomeActive() 호출!
```

### Step 3: FinanceHomeInteractor가 활성화되면서 자식 attach

```swift
// FinanceHomeInteractor.swift
override func didBecomeActive() {
    super.didBecomeActive()

    router?.attachSuperPayDashboard()     // 잔고 대시보드 붙이기
    router?.attachCardOnFileDashboard()   // 카드 목록 붙이기
}
```

### Step 4: Router가 자식 RIB을 실제로 attach

```
FinanceHomeRouter.attachSuperPayDashboard()
    │
    ├── superPayDashboardBuildable.build(withListener: interactor)
    │       │
    │       ├── SuperPayDashboardComponent 생성
    │       │     └── balance 데이터를 FinanceHomeComponent에서 가져옴
    │       ├── SuperPayDashboardViewController 생성
    │       ├── SuperPayDashboardInteractor 생성
    │       └── SuperPayDashboardRouter 생성
    │
    ├── viewController.addDashboard(router.viewControllable)
    │       └── 화면에 잔고 카드 UI 추가
    │
    └── attachChild(router)
            → SuperPayDashboardInteractor.didBecomeActive() 호출!
                └── balance 구독 시작 → 화면에 "10,000원" 표시
```

### Step 5: 최종 화면 구성 결과

```
┌─────────────────────────────┐
│  슈퍼페이 (FinanceHomeVC)     │
│                             │
│  ┌────────────────────────┐ │
│  │ 슈퍼페이 잔고  [충전하기] │ │  ← SuperPayDashboardVC
│  │ ┌──────────────────┐  │ │
│  │ │   10,000    원    │  │ │
│  │ └──────────────────┘  │ │
│  └────────────────────────┘ │
│                             │
│  ┌────────────────────────┐ │
│  │ 카드 및 계좌  [전체보기] │ │  ← CardOnFileDashboardVC
│  │ ┌──────────────────┐  │ │
│  │ │ 우리은행 **** 0123│  │ │
│  │ ├──────────────────┤  │ │
│  │ │ 신한카드 **** 0987│  │ │
│  │ ├──────────────────┤  │ │
│  │ │     + 추가        │  │ │
│  │ └──────────────────┘  │ │
│  └────────────────────────┘ │
└─────────────────────────────┘
```

---

## 9. 앱 전체 흐름: AppDelegate에서 화면까지

앱이 실행될 때 일어나는 일을 순서대로 따라가 봅시다.

### 9.1 시작점: AppDelegate

```swift
// AppDelegate.swift
func application(_ application: UIApplication,
    didFinishLaunchingWithOptions ...) -> Bool {

    let window = UIWindow(frame: UIScreen.main.bounds)
    self.window = window

    // 1. AppRoot RIB 생성
    let result = AppRootBuilder(dependency: AppComponent()).build()

    // 2. 참조 유지
    self.launchRouter = result.launchRouter
    self.urlHandler = result.urlHandler

    // 3. 앱 화면 표시 시작!
    launchRouter?.launch(from: window)

    return true
}
```

### 9.2 전체 실행 흐름

```
① AppDelegate.didFinishLaunching
    │
    ▼
② AppRootBuilder.build()
    ├── AppRootComponent 생성
    ├── RootTabBarController 생성 (TabBar 화면)
    ├── AppRootInteractor 생성
    ├── AppHomeBuilder, FinanceHomeBuilder, ProfileHomeBuilder 생성
    └── AppRootRouter 생성
    │
    ▼
③ launchRouter.launch(from: window)
    ├── window.rootViewController = RootTabBarController
    └── AppRootInteractor.didBecomeActive()
    │
    ▼
④ AppRootInteractor.didBecomeActive()
    ├── router.attachAppHome()      → 홈 탭 생성
    ├── router.attachFinanceHome()  → 슈퍼페이 탭 생성
    └── router.attachProfileHome()  → 프로필 탭 생성
    │
    ▼
⑤ FinanceHomeInteractor.didBecomeActive()
    ├── router.attachSuperPayDashboard()     → 잔고 UI
    └── router.attachCardOnFileDashboard()   → 카드 목록 UI
    │
    ▼
⑥ 화면 표시 완료!
   사용자가 TabBar에서 "슈퍼페이" 탭을 볼 수 있음
```

---

## 10. 자주 하는 실수와 주의사항

### 실수 1: Interactor에서 UIKit import

```swift
// ❌ 잘못된 예시
import UIKit  // Interactor에서 UIKit을 import하면 안 됩니다!

final class FinanceHomeInteractor: ... {
    func showAlert() {
        let alert = UIAlertController(...)  // 금지!
    }
}

// ✅ 올바른 예시
// Interactor는 Presentable 프로토콜을 통해 ViewController에 요청합니다
protocol FinanceHomePresentable: Presentable {
    func showError(message: String)
}

final class FinanceHomeInteractor: ... {
    func handleError() {
        presenter.showError(message: "오류가 발생했습니다")
    }
}
```

### 실수 2: 중복 attach 방지 누락

```swift
// ❌ 잘못된 예시 — 여러 번 호출되면 자식이 중복 생성됩니다
func attachSuperPayDashboard() {
    let router = superPayDashboardBuildable.build(withListener: interactor)
    attachChild(router)  // 매번 새로 만들어서 붙임!
}

// ✅ 올바른 예시 — 이미 있으면 무시
func attachSuperPayDashboard() {
    if superPayingRouting != nil { return }  // 가드!
    let router = superPayDashboardBuildable.build(withListener: interactor)
    self.superPayingRouting = router
    attachChild(router)
}
```

### 실수 3: Listener를 strong 참조

```swift
// ❌ 잘못된 예시 — 순환 참조 발생!
var listener: FinanceHomeListener?

// ✅ 올바른 예시 — 반드시 weak
weak var listener: FinanceHomeListener?
```

### 실수 4: Router에서 비즈니스 로직 작성

```swift
// ❌ 잘못된 예시 — Router는 화면 전환만 담당합니다
func attachSuperPayDashboard() {
    let balance = calculateBalance()  // Router에서 계산하면 안 됩니다!
    ...
}

// ✅ 올바른 예시 — 비즈니스 로직은 Interactor에서
// Interactor에서 판단 후 Router에 요청
func didBecomeActive() {
    if shouldShowDashboard {
        router?.attachSuperPayDashboard()
    }
}
```

### 실수 5: detach 없이 새로운 attach

```swift
// ❌ 잘못된 예시 — 기존 자식을 detach하지 않고 새로 attach
func switchToNewChild() {
    let router = childBuildable.build(withListener: interactor)
    attachChild(router)  // 기존 자식은 아직 트리에 남아있음!
}

// ✅ 올바른 예시 — 기존 자식을 먼저 detach
func switchToNewChild() {
    if let existing = childRouting {
        detachChild(existing)
        self.childRouting = nil
    }
    let router = childBuildable.build(withListener: interactor)
    self.childRouting = router
    attachChild(router)
}
```

### 실수 6: willResignActive에서 구독 해제 누락

```swift
// ❌ 잘못된 예시 — 메모리 누수 발생
override func willResignActive() {
    super.willResignActive()
    // cancellables 정리를 잊었습니다!
}

// ✅ 올바른 예시
override func willResignActive() {
    super.willResignActive()
    cancellables.forEach { $0.cancel() }
    cancellables.removeAll()
}
```

---

## 11. 용어 정리

| 용어 | 한국어 | 설명 |
|------|--------|------|
| **RIB** | 립 | Router + Interactor + Builder의 약자. 하나의 독립적인 기능 단위 |
| **Router** | 라우터 | 자식 RIB의 attach/detach를 관리하는 내비게이션 담당자 |
| **Interactor** | 인터랙터 | 비즈니스 로직을 담당하는 RIB의 두뇌 |
| **Builder** | 빌더 | RIB의 모든 구성 요소를 생성하고 조립하는 팩토리 |
| **Component** | 컴포넌트 | 의존성을 모아두는 컨테이너. 부모 → 자식 데이터 전달에 사용 |
| **Presenter** | 프레젠터 | RIBs에서는 ViewController를 의미 (화면 표시 담당) |
| **Dependency** | 디펜던시 | RIB이 외부에서 필요로 하는 의존성을 선언하는 프로토콜 |
| **Listener** | 리스너 | 자식 → 부모 방향의 이벤트 전달을 위한 프로토콜 |
| **attach** | 어태치 | 자식 RIB을 트리에 연결하여 활성화하는 것 |
| **detach** | 디태치 | 자식 RIB을 트리에서 분리하여 비활성화하는 것 |
| **didBecomeActive** | 활성화 콜백 | RIB이 attach되어 트리에 연결된 직후 호출되는 메서드 |
| **willResignActive** | 비활성화 콜백 | RIB이 detach되기 직전에 호출되는 메서드 |
| **ViewableRouter** | 뷰어블 라우터 | ViewController를 가진 Router (화면이 있는 RIB) |
| **Buildable** | 빌더블 | Builder의 인터페이스 프로토콜. 부모 Router가 이것을 통해 자식을 생성 |
| **PresentableInteractor** | 프레젠터블 인터랙터 | ViewController(Presenter)를 가진 Interactor |
| **ViewControllable** | 뷰 컨트롤러블 | UIViewController를 추상화한 프로토콜. Router가 화면 조작 시 사용 |
| **LaunchRouting** | 런치 라우팅 | 앱의 최초 화면을 윈도우에 표시하는 최상위 Router |

---

## 참고 자료

- [ModernRIBs GitHub](https://github.com/DevYeom/ModernRIBs) — 이 프로젝트에서 사용하는 RIBs 라이브러리
- [Uber RIBs GitHub](https://github.com/nicklama/ribs) — 원본 RIBs 프레임워크
- [RIBs Wiki](https://github.com/nicklama/ribs/wiki) — Uber 공식 RIBs 문서

---

> **다음 학습 추천**: `completed/` 폴더에 있는 완성 코드를 비교하면서 Topup(충전) RIB, AddPaymentMethod(결제수단 추가) RIB이 어떻게 구성되는지 살펴보세요. 모달 표시, 내비게이션 스택 등 더 다양한 화면 전환 패턴을 배울 수 있습니다.
