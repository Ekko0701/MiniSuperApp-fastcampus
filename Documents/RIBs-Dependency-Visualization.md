# RIBs Dependency 시각화 가이드

> MiniSuperApp 프로젝트의 실제 코드를 기반으로 Dependency와 Component의 흐름을 시각화합니다.

---

## 1. 핵심 개념: 위로 요청, 아래로 전달

### 간단한 비유

```
할아버지 (AppRoot)
    │
    ├─ "용돈 주세요" ← 아빠 (FinanceHome) → "용돈 줄게"
    │                                            │
    │                                            ├─ "용돈 주세요" ← 손자1 (SuperPayDashboard)
    │                                            └─ "용돈 주세요" ← 손자2 (CardOnFileDashboard)
```

**Dependency**: 자식이 부모에게 보내는 요청서 ("이거 필요해요!")
**Component**: 부모가 자식에게 주는 도구 상자 ("여기 있어!")

---

## 2. FinanceHome 예시로 보는 전체 흐름

### 2.1 등장인물 소개

```
AppRoot (할아버지)
    │
    └── FinanceHome (아빠)
            │
            ├── SuperPayDashboard (손자1) - 잔고 표시
            ├── CardOnFileDashboard (손자2) - 카드 목록
            └── AddPaymentMethod (손자3) - 카드 추가
```

### 2.2 무엇이 필요한가?

| RIB | 필요한 것 |
|-----|-----------|
| **SuperPayDashboard** | `balance` (잔고 데이터) |
| **CardOnFileDashboard** | `cardOnFileRepository` (카드 저장소) |
| **AddPaymentMethod** | `cardOnFileRepository` (카드 저장소) |

---

## 3. Dependency 프로토콜 (요청서)

### 손자들이 작성한 요청서

```swift
// 손자1의 요청서
protocol SuperPayDashboardDependency: Dependency {
    var balance: ReadOnlyCurrentValuePublisher<Double> { get }
}
// "아빠, 나한테 잔고 데이터 줘!"

// 손자2의 요청서
protocol CardOnFileDashboardDependency: Dependency {
    var cardOnFileRepository: CardOnFileRepository { get }
}
// "아빠, 나한테 카드 저장소 줘!"

// 손자3의 요청서
protocol AddPaymentMethodDependency: Dependency {
    var cardOnFileRepository: CardOnFileRepository { get }
}
// "아빠, 나한테도 카드 저장소 줘!"
```

---

## 4. Component (도구 상자) - 핵심!

### FinanceHomeComponent가 하는 일

```swift
final class FinanceHomeComponent: Component<FinanceHomeDependency>, 
    SuperPayDashboardDependency,      // ← 손자1 요청 충족
    CardOnFileDashboardDependency,    // ← 손자2 요청 충족
    AddPaymentMethodDependency {      // ← 손자3 요청 충족
    
    // 📦 내가 가진 것들 (도구 상자 안에 있는 도구)
    let cardOnFileRepository: CardOnFileRepository
    var balance: ReadOnlyCurrentValuePublisher<Double> { balancePublisher }
    private let balancePublisher: CurrentValuePublisher<Double>
    
    init(
        dependency: FinanceHomeDependency,  // ← 할아버지(AppRoot)가 준 것
        balance: CurrentValuePublisher<Double>,     // ← 내가 만든 것
        cardOnFileRepository: CardOnFileRepository  // ← 내가 만든 것
    ) {
        self.balancePublisher = balance
        self.cardOnFileRepository = cardOnFileRepository
        super.init(dependency: dependency)
    }
}
```

**Component가 하는 일 3가지**:

1. **받는다** (위에서): `dependency: FinanceHomeDependency` - 부모가 준 것
2. **만든다** (자체): `balance`, `cardOnFileRepository` - 내가 생성한 것
3. **준다** (아래로): 손자들의 Dependency 프로토콜 채택 - 자식들에게 전달

---

## 5. 데이터 흐름 전체 다이어그램

```
┌─────────────────────────────────────────────────────────────────┐
│                        AppRootComponent                          │
│                        (할아버지의 도구 상자)                       │
│                                                                  │
│  채택: FinanceHomeDependency                                     │
│  제공: (현재는 비어있음 - FinanceHome이 스스로 생성)                │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          │ FinanceHomeDependency 전달
                          │ (프로토콜 타입으로)
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                     FinanceHomeBuilder                           │
│                                                                  │
│  func build(withListener listener: FinanceHomeListener)         │
│      -> FinanceHomeRouting {                                    │
│                                                                  │
│      // Component 생성 - 도구 상자 준비!                           │
│      let component = FinanceHomeComponent(                       │
│          dependency: dependency,              // ← 위에서 받음    │
│          balance: CurrentValuePublisher(10000),  // ← 새로 만듦   │
│          cardOnFileRepository: CardOnFileRepositoryImp()  // ← 새로 만듦 │
│      )                                                           │
│                                                                  │
│      // 손자 Builder들 생성 - Component를 주입!                    │
│      let superPayBuilder =                                       │
│          SuperPayDashboardBuilder(dependency: component)         │
│      let cardOnFileBuilder =                                     │
│          CardOnFileDashboardBuilder(dependency: component)       │
│      let addPaymentBuilder =                                     │
│          AddPaymentMethodBuilder(dependency: component)          │
│  }                                                               │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          │ component 전달
                          │ (SuperPayDashboardDependency,
                          │  CardOnFileDashboardDependency,
                          │  AddPaymentMethodDependency 타입으로)
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  SuperPay    │  │  CardOnFile  │  │ AddPayment   │
│  Dashboard   │  │  Dashboard   │  │  Method      │
│  Builder     │  │  Builder     │  │  Builder     │
└──────────────┘  └──────────────┘  └──────────────┘
```

---

## 6. Component의 마법: 하나의 객체, 여러 얼굴

이것이 가장 헷갈리는 부분입니다! **같은 객체**가 **다른 타입**으로 보입니다.

```
                    FinanceHomeComponent 객체
                    (실제로는 하나의 인스턴스)
                            │
            ┌───────────────┼───────────────┐
            │               │               │
            ▼               ▼               ▼
    SuperPayDashboard   CardOnFile   AddPaymentMethod
    Dependency 타입     Dependency   Dependency 타입
                        타입
            │               │               │
            ▼               ▼               ▼
    "balance만          "cardOnFile      "cardOnFile
     보임"              Repository만      Repository만
                        보임"            보임"
```

### 코드로 보면

```swift
// 1. Component 하나 생성
let component = FinanceHomeComponent(...)

// 2. 같은 component를 다른 Builder들에게 전달
let superPayBuilder = SuperPayDashboardBuilder(dependency: component)
//                                             ^^^^^^^^^
//                                             타입: SuperPayDashboardDependency

let cardOnFileBuilder = CardOnFileDashboardBuilder(dependency: component)
//                                                  ^^^^^^^^^
//                                                  타입: CardOnFileDashboardDependency
```

**Swift의 프로토콜 다형성**: 같은 객체가 여러 프로토콜을 채택하면, 각 프로토콜 타입으로 전달될 때 **해당 프로토콜에 정의된 프로퍼티/메서드만** 접근 가능합니다.

---

## 7. 실제 사용 예시: SuperPayDashboard

### 전체 흐름

```
① FinanceHomeBuilder에서 Component 생성
    │
    ▼
② SuperPayDashboardBuilder에게 Component 전달 (SuperPayDashboardDependency 타입)
    │
    ▼
③ SuperPayDashboardComponent에서 부모 Component의 balance에 접근
    │
    ▼
④ SuperPayDashboardInteractor에서 balance 구독
    │
    ▼
⑤ 화면에 "10,000원" 표시
```

### 코드로 따라가기

**① FinanceHomeBuilder - Component 생성**

```swift
let balancePublisher = CurrentValuePublisher<Double>(10000)

let component = FinanceHomeComponent(
    dependency: dependency,
    balance: balancePublisher,  // ← 여기서 생성!
    cardOnFileRepository: CardOnFileRepositoryImp()
)
```

**② SuperPayDashboardBuilder로 전달**

```swift
let superPayDashboardBuilder = SuperPayDashboardBuilder(dependency: component)
//                                                       ^^^^^^^^^
//                            타입: SuperPayDashboardDependency
//                            실제: FinanceHomeComponent 인스턴스
```

**③ SuperPayDashboardComponent에서 접근**

```swift
final class SuperPayDashboardComponent: 
    Component<SuperPayDashboardDependency>,
    SuperPayDashboardInteractorDependency {
    
    var balance: ReadOnlyCurrentValuePublisher<Double> { 
        dependency.balance  // ← 부모 Component의 balance에 접근
    }
    
    var balanceFormatter: NumberFormatter { 
        Formatter.balanceFormatter 
    }
}
```

**④ SuperPayDashboardInteractor에서 구독**

```swift
final class SuperPayDashboardInteractor: ... {
    private let dependency: SuperPayDashboardInteractorDependency
    
    override func didBecomeActive() {
        dependency.balance.sink { [weak self] balance in
            //      ^^^^^^^ 
            //      Component → Component → Publisher
            self?.dependency.balanceFormatter
                .string(from: NSNumber(value: balance))
                .map { self?.presenter.updateBalance($0) }
        }.store(in: &cancellables)
    }
}
```

**⑤ ViewController에서 화면 업데이트**

```swift
func updateBalance(_ balance: String) {
    balanceAmountLabel.text = balance  // "10,000"
}
```

---

## 8. CardOnFileDashboard & AddPaymentMethod의 공유

두 손자가 **같은 Repository**를 사용합니다:

```
FinanceHomeComponent
    │
    └── cardOnFileRepository: CardOnFileRepository
                │
                ├─→ CardOnFileDashboard가 사용 (카드 목록 읽기)
                └─→ AddPaymentMethod가 사용 (카드 추가)
```

### 코드로 보기

```swift
// FinanceHomeComponent - 한 번만 생성
final class FinanceHomeComponent: ..., 
    CardOnFileDashboardDependency,
    AddPaymentMethodDependency {
    
    let cardOnFileRepository: CardOnFileRepository
    //  ^^^^^^^^^^^^^^^^^^^^
    //  두 프로토콜 모두 이 프로퍼티를 요구하므로,
    //  하나만 선언해도 두 프로토콜을 모두 충족!
}

// CardOnFileDashboard에서 사용
dependency.cardOnFileRepository.cardOnFile.sink { methods in
    self.presenter.update(with: viewModels)
}

// AddPaymentMethod에서 사용
dependency.cardOnFileRepository.addCard(info: info).sink { method in
    self.listener?.addPaymentMethodDidAddCard(paymentMethod: method)
}
```

**같은 Repository 인스턴스**를 공유하므로, AddPaymentMethod에서 카드를 추가하면 CardOnFileDashboard가 자동으로 업데이트됩니다 (Publisher/Subscriber 패턴).

---

## 9. 정리: Dependency vs Component

### Dependency (요청서)

```swift
protocol SuperPayDashboardDependency: Dependency {
    var balance: ReadOnlyCurrentValuePublisher<Double> { get }
}
```

- **방향**: 자식 → 부모 (위로 향함)
- **의미**: "나를 만들려면 이것이 필요해요"
- **누가 준수**: 부모의 Component
- **언제 정의**: 자식 RIB의 Builder 파일에서

### Component (도구 상자)

```swift
final class FinanceHomeComponent: Component<FinanceHomeDependency>,
    SuperPayDashboardDependency,      // 손자1 요청 충족
    CardOnFileDashboardDependency,    // 손자2 요청 충족
    AddPaymentMethodDependency {      // 손자3 요청 충족
    
    let cardOnFileRepository: CardOnFileRepository
    var balance: ReadOnlyCurrentValuePublisher<Double> { balancePublisher }
}
```

- **방향**: 부모 → 자식 (아래로 향함)
- **의미**: "내가 가진 것과 받은 것을 자식들에게 줄게"
- **역할**: 자식들의 Dependency 프로토콜 채택
- **언제 정의**: 부모 RIB의 Builder 파일에서

### 흐름 요약

```
자식: "이거 필요해요!" (Dependency 프로토콜 정의)
    │
    ▼
부모: "알았어, 여기 있어!" (Component가 프로토콜 채택)
    │
    ▼
부모: Builder에서 Component를 자식 Builder에게 전달
    │
    ▼
자식: Component를 통해 필요한 것을 받아서 사용
```

---

## 10. 한 눈에 보는 다이어그램

```
╔═══════════════════════════════════════════════════════════════╗
║                    AppRootComponent                           ║
║                    (할아버지 도구 상자)                          ║
╚═══════════════════════════════════════════════════════════════╝
                            │
                            │ 전달 (dependency)
                            ▼
╔═══════════════════════════════════════════════════════════════╗
║              FinanceHomeComponent (아빠 도구 상자)              ║
║                                                               ║
║  📦 내가 만든 것:                                              ║
║    • balance: CurrentValuePublisher<Double>                  ║
║    • cardOnFileRepository: CardOnFileRepository              ║
║                                                               ║
║  🎭 여러 얼굴 (프로토콜 채택):                                  ║
║    • SuperPayDashboardDependency                             ║
║    • CardOnFileDashboardDependency                           ║
║    • AddPaymentMethodDependency                              ║
╚═══════════════════════════════════════════════════════════════╝
          │                    │                    │
          │ balance            │ cardOnFile...      │ cardOnFile...
          │ 전달                │ 전달               │ 전달
          ▼                    ▼                    ▼
    ┌──────────┐         ┌──────────┐         ┌──────────┐
    │ SuperPay │         │CardOnFile│         │AddPayment│
    │Dashboard │         │Dashboard │         │  Method  │
    └──────────┘         └──────────┘         └──────────┘
    "10,000원"           "카드 목록"            "카드 추가"
```

---

## 11. 헷갈릴 때 체크리스트

✅ **Dependency**: 자식이 정의 → 부모가 채택
✅ **Component**: 부모가 정의 → 자식 Dependency들을 채택
✅ **같은 Component 객체**가 **다른 프로토콜 타입**으로 전달됨
✅ **Builder에서 Component 생성** → **자식 Builder들에게 주입**
✅ Component는 **위에서 받은 것 + 자체 생성한 것**을 합쳐서 **아래로 전달**

---

이제 명확해지셨나요? 추가로 궁금한 부분이 있으면 말씀해주세요!
