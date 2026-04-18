# Dev Quest Library — Phase 2 설계 문서

> Phase 1 배포 이후 다음 개발 사이클. 구조 조립 시뮬레이터(MSA)로 "게임형 학습"이 마크다운 대비 실제로 낫다는 증거 확보가 목표.

- **작성일**: 2026-04-18
- **브랜치**: `develop`
- **Phase 1 상태**: 프로덕션 배포 완료 (https://public-project-area-oragans.github.io/dol/)
- **Status**: APPROVED (office-hours 세션 산출, 2026-04-18 승인)
- **Mode**: Startup (pre-product / 1→4→3 진화 경로)
- **원설계 문서**: `docs/2026-04-17-dev-quest-library-design.md` 연장

---

## 1. 문제 정의

**완성도 기준 명시:** 이 문서의 "완성도"는 **1단계(개인용)의 완성 버전을 100으로 잡은 척도**다. 4단계(사내)·3단계(공개)는 1단계 완성 뒤에 재평가할 별개의 로드맵이며, 이 문서의 완성도 분모에 포함되지 않는다.

Phase 1은 **1단계(개인용) 완성 버전 기준 ~20% 미만** 수준이다. "이론 카드 + 객관식 퀴즈"만 있는 현재 상태는 **마크다운 뷰어와 구조적으로 다른 점이 아직 없다**. 게임화 골조(Flame 씬, NPC 대화, 퀘스트, Gist 저장)는 완성했으나, 학습 경험 자체의 차별점은 증명되지 않았다.

핵심 질문: **"이 게임 하니까 마크다운 읽는 것보다 뭐가 달라지는가?"** 이것이 1단계 기준에서 답해지지 않으면 4·3단계는 논의할 가치가 없다.

---

## 2. 사용자 진화 경로 (1→4→3)

| 단계 | 타겟 | 검증 지표 |
|------|------|----------|
| 1. 개인 학습·재미 (현재) | 본인 | 본인이 일주일 실사용해 "마크다운보다 낫다" 체감 |
| 4. 사내 교육 (다음) | 사내 신입·주니어 | 이해관계자 설득용 계측 데이터 + 교육 파일럿 |
| 3. 공개 서비스 (장기) | 개발 학습자 전반 | 실사용자 리텐션·완료율·유료 전환 |

**지금 결정:** 1단계에서 "가치 명제가 진짜인지" 증명 못 하면 4, 3으로 못 넘어간다.

---

## 3. 수요 증거 (현 상태)

- **검증된 수요:** 없음. 본인 실사용도 아직 안 했음. Phase 1은 완성 직후.
- **간접 신호:** `develop-study-documents` 레포에 181챕터 학습 콘텐츠를 본인이 직접 축적 → 학습 문서 소비·정리의 니즈는 본인 안에 있음.
- **위험 신호:** 사용자 스스로 "완성도 80%가 되어야 검증 가능"이라 표현 → 플랫폼형 사고. 작은 슬라이스로도 가치 증명이 가능해야 건강한 프레임.

---

## 4. Status Quo

- **본인 학습 방식 (현재):** GitHub 마크다운 원본을 IDE/VSCode에서 스크롤. 챕터 드문드문 건너뜀. 기억에 남는 부분 제한.
- **개발 학습 일반:** 책(종이/eBook), 인프런·유데미 강의, 블로그 요약, 공식 문서. 모두 수동적 소비 중심. 게임화 시도는 SoloLearn·Codecademy가 있으나 개발 문서 전체가 아닌 "튜토리얼 트랙"에 한정.

경쟁은 **"본인이 매일 여는 docs-source 레포의 Raw MD 뷰"** 이다. 이보다 명확히 나아야 한다.

---

## 5. 타겟 사용자 & Narrowest Wedge

**1단계 타겟 사용자:** 본인 (이 프로젝트의 주 저자/소비자).

**Narrowest Wedge:**
- 카테고리: **MSA** (46챕터, 본인이 상대적으로 덜 익숙 → 학습 체감 가능)
- 시뮬레이터 타입: **구조 조립 (Structure Assembly)**
- 슬라이스 크기: **3챕터 확정** — `phase4-step1-api-gateway`, `phase4-step2-service-discovery`, `phase4-step4-resilience-patterns`
- 성공 기준: 본인이 일주일 실사용해 "이 챕터는 게임으로 배우니 마크다운보다 기억에 남는다"를 *문장으로 쓸 수 있음*

> **Outside Voice 반영 (T3):** 초기 후보였던 "Saga 패턴"은 `docs-source/MSA/` 실제 목차에 독립 챕터 없음(`phase3-step3-data-decomposition`의 하위 주제). `phase4-step4-resilience-patterns`(Circuit Breaker·Retry·Bulkhead·Fallback)로 교체 — 서비스 간 방어층 구조가 구조 조립 메커니즘에 더 잘 맞음.

---

## 6. 전제 (Premises)

### P1 (수정본) — 구조 조립 시뮬레이터 먼저
3종 시뮬레이터 중 **구조 조립**이 Phase 2의 첫 타자. 이유: 시각적 임팩트가 가장 크고, 게임 세계관(분관·스팀펑크·픽셀아트)과 가장 자연스럽게 결합. SQL 실습·흐름 추적은 Phase 3 이후.

**주의:** 구조 조립은 SQL보다 UI 구현 난이도가 2~3배(드래그&드롭, 부분 정답, 판정 애니메이션). Phase 2 기간·완성도 기대치를 이에 맞춰 조정.

### P2 (수정본) — MSA × 구조 조립 × 3~5챕터 슬라이스
5개 분관 × 3종 시뮬레이터 × 181챕터를 한꺼번에 만들지 않는다. MSA 분관에서 구조 조립 챕터 3~5개만 완성 → 본인 일주일 실사용 → **다음 축(추가 카테고리·추가 시뮬레이터·보상 엔진)은 그 피드백으로 결정**.

### P3 — 가치 명제 증명이 모든 확장의 조건
시뮬레이터 추가·보상 엔진·다층 도서관·신규 카테고리·BGM 등 설계 문서 10.3의 모든 확장안은 **P1+P2의 슬라이스가 "게임 방식이 낫다"를 증명한 이후에만** 우선순위를 재평가한다. 증명 전에 미리 투자하지 않는다.

---

## 7. 접근법 비교

### Approach A — 최소 MVP (Flutter 그리드 드래그&드롭)
- **개념:** Flutter `Draggable` / `DragTarget` 기반의 단일 오버레이 화면. 좌측 팔레트에서 서비스 블록(API Gateway, Service A, DB 등)을 그리드 캔버스로 드래그. 연결선은 블록 탭 → 연결 버튼으로 지정.
- **범위:** MSA 3챕터 (API Gateway, Service Discovery, Resilience Patterns)
- **노력:** S (1~2주, CC+gstack 기준)
- **리스크:** 낮음
- **장점:** 기존 `overlays/` 패턴 재활용. Flame 개입 없음. 검증 루프 최단.
- **단점:** "게임답지 않음". 중앙 홀·NPC 세계관과 UI 이질감.
- **재활용:** `lib/presentation/overlays/`, `lib/presentation/widgets/steampunk_button.dart`, 기존 `QuizOverlay` 판정 로직.

### Approach B — 이상적 (Flame 컴포넌트 + 스팀펑크 픽셀아트 캔버스)
- **개념:** Flame `GameWidget` 위에 서비스 컴포넌트를 스팀펑크 픽셀아트(톱니·증기 파이프 모티프)로 배치. 드래그는 Flame `DragCallbacks`. 연결선은 Flame의 `LineComponent`. 옆 오버레이로 단계 지시와 판정 결과.
- **범위:** MSA 5챕터 (A의 3개 + Circuit Breaker + Event-driven)
- **노력:** L (5~8주)
- **리스크:** 중 (Flame 드래그 판정, 스프라이트 제작)
- **장점:** 세계관 유지, PixelLab MSA 서비스 스프라이트 생성 필요 → 장기 에셋 자산.
- **단점:** 검증 사이클 지연. "게임 방식이 낫다"가 증명되기 전에 비주얼에 큰 투자.

### Approach C — 창의적 (고장난 구조 진단 모드)
- **개념:** 드래그&드롭 없음. "고장난 MSA 구조"를 미리 배치하고, 사용자가 각 노드를 클릭해 잘못된 점을 찾아 수정. "조립"이 아니라 "디버그 진단".
- **범위:** MSA 3챕터 × 버그 시나리오 3개씩
- **노력:** M (3~4주)
- **리스크:** 중 (콘텐츠 제작 부담)
- **장점:** UI 구현 간단 (클릭+모달), "이 문제 풀려면 공부해야겠다" 학습 동기 최강.
- **단점:** "구조 조립"이라는 본래 메커니즘에서 벗어남. 설계 문서 대폭 수정 필요.

---

## 8. 추천 접근법 — A → B 단계별

**결정:** 먼저 Approach A로 1~2주 내 슬라이스 스파이크 → 본인 실사용 → 학습 효과 체감되면 Approach B 수준의 Flame+픽셀아트 업그레이드.

**근거:**
1. "게임 방식이 낫다"를 증명한 뒤 시각 투자를 하는 것이 ROI가 맞음.
2. 사용자 스스로 "완성도 80%가 되어야 검증 가능"이라는 플랫폼형 사고를 드러냄 → 짧은 검증 루프로 프레임을 깨는 것이 Phase 2의 일차 목적.
3. A로 검증 실패(= 마크다운 대비 체감 없음) 시 B에 투자한 비용을 아낄 수 있음.

---

## 9. 구현 범위 (Phase 2 Task 목록)

### Task 2-0: override JSON 스키마 설계 (Outside Voice 반영 — T5 신설)

Critic 지적: 스키마가 Task 2-2(시뮬레이터 위젯)의 데이터 모델을 결정하므로 다른 Task의 **선행 과제**. 원래 Task 2-1로 묶였던 것을 분리.

- `content/overrides/msa/<chapter-id>.json` 스키마 정의:
  ```json
  {
    "chapterId": "msa-phase4-step1-api-gateway",
    "simulator": {
      "type": "structureAssembly",
      "gridSize": {"cols": 5, "rows": 5},
      "palette": [{"id": "gateway", "label": "API Gateway", "spriteKey": "service_gateway"}, ...],
      "solution": {
        "nodes": [{"id": "gateway", "pos": {"col": 2, "row": 0}}, ...],
        "edges": [{"from": "gateway", "to": "serviceA", "directed": true}, ...]
      },
      "partialFeedback": {
        "missingNodes": "필수 컴포넌트가 빠졌습니다: {names}",
        "missingEdges": "다음 연결이 필요합니다: {pairs}",
        "extraEdges": "불필요한 연결이 있습니다: {pairs}"
      }
    }
  }
  ```
- 이 스키마를 `lib/data/models/book_model.dart`의 `StructureAssemblyConfig` freezed 서브타입이 그대로 매핑.
- 스키마 합의 → Task 2-1 착수.

### Task 2-1: MSA 3챕터 override JSON 작성
- 확정된 3챕터(`phase4-step1-api-gateway`, `phase4-step2-service-discovery`, `phase4-step4-resilience-patterns`)의 정답 그래프를 Task 2-0 스키마로 기입.
- 각 챕터의 "조립 목표 구조"를 먼저 종이/초안으로 스케치 후 JSON 작성.
- 본인이 docs-source 원문을 읽고 **스스로 맞다고 판단하는 구조**를 정답 그래프로 정의.

### Task 2-2: `StructureAssemblySimulator` 위젯
- `lib/presentation/simulators/structure_assembly_simulator.dart`
- `Draggable` / `DragTarget` + 그리드 스냅.
- 연결선: 블록 탭 → "연결" 모드 진입 → 다른 블록 탭으로 엣지 생성.

**레이아웃 와이어프레임 (plan-design-review 반영):**

```
┌──────────────────────────────────────────────────────────────────┐
│  📖 이론  │  ⚡ 시뮬레이터                  [3/5]  [리셋] [판정]  │ ← AppBar + Tabs
├──────────────────────────────────────────────────────────────────┤
│ ╔══════════════════════════════════════════════════════════╗    │
│ ║  🪙 API Gateway Pattern                                  ║    │ ← 조립 지시문
│ ║  외부 요청이 올바른 서비스로 라우팅되는 구조를 조립하세요.║    │   (Pass 1-A 반영)
│ ║                                                          ║    │   gold ornament
│ ╚══════════════════════════════════════════════════════════╝    │   frame
├──────────────┬───────────────────────────────────────────────────┤
│  PALETTE     │  CANVAS (5×5 grid, parchment bg, gold lines)     │
│              │                                                   │
│ ┌──────────┐ │   ┌────┐    ┌────┐                               │
│ │⚙ Gateway│ │   │ GW │────▶│ SD │                               │
│ ├──────────┤ │   └────┘    └────┘                               │
│ │⚙ Service│ │      │         │                                  │
│ ├──────────┤ │      ▼         ▼                                 │
│ │🧪 Database│ │   ┌────┐    ┌────┐                               │
│ ├──────────┤ │   │ S1 │    │ S2 │                               │
│ │💎 Cache │ │    └────┘    └────┘                               │
│ ├──────────┤ │                                                   │
│ │♨ Queue │ │    (빈 칸은 파치먼트 그리드 그대로)                │
│ ├──────────┤ │                                                   │
│ │⚖ LoadBal│ │                                                   │
│ └──────────┘ │                                                   │
│              │                                                   │
│ [연결 모드]  │                                                   │
└──────────────┴───────────────────────────────────────────────────┘
```

**시각 스펙 (AppColors 기반):**
- **배경:** `darkWalnut #0F0B07` (전체)
- **패널 (팔레트·지시문 frame):** `deepPurple #1A1420` + `gold #B8860B` 1.5px border
- **캔버스 배경:** `parchment #F5EFE0` + `gold` 십자선 (alpha 0.3)
- **노드 블록 (팔레트 idle):** `midPurple #2A1F30` + `gold` 1px 외곽
- **노드 블록 (캔버스 배치):** `deepPurple` + `brightGold #FFD700` 2px 외곽 (강조)
- **드래그 중 feedback:** 원본 노드 50% alpha + `magicPurple #7B68EE` glow
- **연결선 (완성):** `gold` 2px solid, 화살촉
- **연결선 (생성 중):** `magicPurple` 2px dashed, 화살촉 따라감
- **연결 모드 활성:** 팔레트 하단 "[연결 모드]" 뱃지 `steamGreen #2E8B57` bg
- **판정 버튼 (기본):** `gold` bg + `darkWalnut` text, 리벳 장식
- **판정 버튼 (처리 중):** `gold` outline만 + 회전 톱니 아이콘
- **판정 결과 (성공):** 전체 캔버스 `steamGreen` 2초 glow + SteampunkPanel 모달 "✓ 통과!"
- **판정 결과 (부분):** 해당 엣지만 빨갛게 깜빡임 + 인라인 토스트 (`deepPurple` bg, 누락/잘못된 연결 지적)
- **판정 결과 (완전 실패):** 진동 애니메이션 0.3초 + 힌트 버튼 활성화

**상태별 empty/loading/error:**
- **빈 캔버스 (첫 진입):** 캔버스 중앙에 `parchment` alpha 0.4 텍스트 "← 팔레트에서 블록을 끌어와 배치하세요"
- **override JSON 로드 중:** 팔레트+캔버스 skeleton (SteampunkPanel frame만 + 톱니 회전)
- **override JSON 로드 실패:** 캔버스 중앙 "이 챕터의 구조 데이터를 불러올 수 없습니다" + 재시도 버튼
- **판정 전(placed < min):** 판정 버튼 disabled + 툴팁 "최소 N개 이상 배치 후 판정 가능"

**User Journey (Pass 3 반영, 감정 여정):**

| 단계 | 사용자 동작 | 감정 | 시각적 지원 |
|------|-------------|------|-------------|
| 1 | 시뮬레이터 탭 진입 | 호기심 | 조립 지시문 헤더 페이드인 + 팔레트·캔버스 동시 등장 |
| 2 | 팔레트 관찰 | 탐색 | 각 블록 hover 시 `magicPurple` glow + 툴팁 (블록 이름+역할 한 줄) |
| 3 | 첫 드래그 시작 | 시도 | 커서가 grab → grabbing, 캔버스에 그리드 셀 하이라이트 |
| 4 | 드롭 성공 | 확신/의심 | 노드가 셀에 스냅 애니메이션(0.15s ease-out) + `brightGold` 펄스 1회 |
| 5 | 연결 모드 진입 | 고민 | 선택한 노드 주변 `magicPurple` halo, 팔레트 하단 "[연결 모드]" 뱃지 |
| 6 | 연결 완료 | 진전 | 엣지 그리기 애니메이션(0.3s 좌→우) + 화살촉 페이드인 |
| 7 | 판정 대기 | 긴장 | 판정 버튼 글로우 호흡 애니메이션 |
| 8 | 판정 통과 | 성취 | 전체 `steamGreen` 2초 glow + SteampunkPanel 모달 "✓ 통과!" + XP 획득 연출 |
| 9 | 부분 실패 | 도전 | 틀린 엣지 빨강 깜빡임 3회 + 인라인 토스트 (어느 연결이 문제인지) |
| 10 | 재시도 | 학습 | 토스트의 "수정하기" 클릭 → 해당 엣지 삭제 + 연결 모드 자동 진입 |
| 11 | 완전 실패 | 좌절 후 회복 | 캔버스 0.3초 진동 + "힌트 보기" 버튼 활성화 (정답 그래프 실루엣 30% alpha 1회 깜빡) |

**Time-horizon design:**
- **5초 (visceral):** 스팀펑크 프레임·gold ornament·parchment texture가 "여기는 보통 앱이 아니다" 인지 (Phase 1 세계관 유지).
- **5분 (behavioral):** 드래그→연결→판정 루프가 망설임 없이 돌아감 (tooltip·state feedback 촘촘).
- **5년 (reflective):** 챕터별 "손으로 조립한 구조"를 기억. 마크다운을 다시 읽을 때 "나는 이걸 도서관 분관에서 조립했다"는 맥락 회상.

**접근성 스펙 (Pass 6 반영 — 전체 대체 경로, 장기 선투자):**

1. **키보드 드래그 대체:**
   - `Tab`: 팔레트 → 캔버스 셀 → 판정 버튼 순환. 포커스 링 `brightGold` 2px outline.
   - 팔레트 블록 포커스 + `Space`: "선택됨" 상태 진입 (aria-live="polite" 음성 안내).
   - 캔버스 셀 포커스 + 화살표: 셀 간 이동.
   - 선택된 블록 있는 상태 + 셀 포커스 + `Enter`: 해당 셀에 배치.
   - 캔버스 노드 포커스 + `Space`: 연결 모드 진입 (aria-live).
   - 연결 모드 + 다른 노드 포커스 + `Enter`: 엣지 생성.
   - `Esc`: 현재 모드 취소.
   - `Delete`: 포커스된 노드·엣지 삭제.

2. **스크린리더 (aria):**
   - 컨테이너: `role="application"` + `aria-label="MSA 구조 조립 시뮬레이터"`.
   - 팔레트: `role="listbox"` + 각 블록 `role="option"` + `aria-describedby`로 역할 설명.
   - 캔버스: `role="grid"` + `aria-rowcount=5` `aria-colcount=5`.
   - 각 셀: `role="gridcell"` + `aria-label="2행 3열, API Gateway 배치됨, 2개 연결"`.
   - 판정 결과: `role="status"` + `aria-live="assertive"` (성공·실패·부분)
   - 힌트: `aria-live="polite"`로 "2행 3열의 API Gateway는 1행 2열의 Client와 연결되어야 합니다" 식 구체 안내.

3. **대비 & 타겟:**
   - WCAG AA 준수 확인 필요 페어:
     - `gold #B8860B` on `darkWalnut #0F0B07` — 대비비 확인 (추정 8:1+, PASS 예상).
     - `parchment #F5EFE0` on `deepPurple #1A1420` — 대비비 확인 (추정 14:1+, PASS 예상).
     - `steamGreen #2E8B57` on `darkWalnut` — 대비비 3.5:1 근처 우려, **검증 후 필요 시 brightGold로 대체**.
   - 터치 타겟: 모든 인터랙티브 요소 최소 44×44px (노드·팔레트 블록·버튼·삭제 아이콘).
   - 드래그 핸들: 44px 미만이면 invisible padding으로 hit area 확장.

4. **고대비 모드 / prefers-reduced-motion:**
   - `MediaQuery.of(context).disableAnimations == true`일 때 모든 애니메이션 instant로 전환 (스냅, 펄스, glow).
   - `MediaQuery.highContrast`일 때 `gold` border 2px → 3px + 모든 alpha 제거.

5. **태블릿 터치 (모바일 fallback이 아니라 지원 대상):**
   - 768px~1024px viewport: 팔레트를 상단 가로 스크롤 바로 배치, 캔버스 하단.
   - 노드 long-press 100ms로 드래그 시작 (모바일 100% fallback과 차별화).

6. **테스트:**
   - `test/presentation/simulators/structure_assembly_a11y_test.dart` 추가:
     - 키보드만으로 완주 가능 검증.
     - `SemanticsTester`로 aria 레이블 존재 검증.
     - `MediaQuery(disableAnimations: true)` 하에서 애니메이션 건너뜀 검증.

### Task 2-3: 판정 로직
- 정답 그래프(노드+엣지)와 사용자 그래프 비교.
- 완전 일치 / 부분 일치 / 완전 실패 상태 구분.
- 부분 일치 피드백: "API Gateway 위치는 맞음. Service Discovery 연결이 빠짐." 수준.

### Task 2-4: 기존 책 열람 흐름 연결
- `book_reader_screen.dart`에서 챕터 타입이 `structureAssembly`일 때 새 시뮬레이터 오버레이 호출.
- 완료 시 기존 `PlayerProgress` 저장 파이프라인 재사용.

### Task 2-5 (검증 도구, 최소치)
- 챕터 시작·완료·재시도 이벤트를 로컬 JSON에 덧붙임 (Hive Box 재활용).
- 본인 일주일 실사용 후 해당 로그를 조회해 "재시도 횟수", "완료까지 걸린 시간" 확인.
- 대시보드 UI 불필요. `print`/로그 뷰어 수준.

### Task 2-6 (테스트, boil the lake — /plan-eng-review 결과 반영)

**Unit (Pure Dart):**
- `test/domain/usecases/graph_validator_test.dart` — 완전 일치 / 노드 개수 불일치 / 노드 종류 불일치 / 엣지 방향 뒤집힘 / 부분 정답 / 빈 그래프 / 중복 엣지 정규화 (최소 7 케이스).
- `test/tools/content_builder_override_test.dart` — overrides 디렉토리 없음(기본값 유지, 경고) / 챕터 ID 매칭 / JSON 파싱 성공 / JSON 파싱 실패(빌드 중단 예외) (최소 4 케이스).
- `test/data/models/book_model_simulator_test.dart` — CodeStepConfig.fromJson 하위호환(기존 book.json 로드) / StructureAssemblyConfig.fromJson / unionKey type 누락 시 fallback (최소 3 케이스).

**Widget:**
- `test/presentation/simulators/structure_assembly_simulator_test.dart` — 팔레트→캔버스 드롭 / 캔버스→캔버스 이동 / 캔버스 밖 드롭 취소 / 노드 A 탭→B 탭→엣지 생성 / self-loop 방지 / 중복 엣지 방지 / 정답→onComplete 호출 / 오답→피드백 표시 / 빈 캔버스 판정→피드백 / 오답→재시도→정답 (최소 10 케이스).
- `test/presentation/screens/book_reader_simulator_routing_test.dart` — **CRITICAL 회귀 1**: CodeStepConfig → CodeStepSimulator 정상 라우팅 / StructureAssemblyConfig → 새 시뮬레이터 렌더 / unknown type → "준비 중" fallback (최소 3 케이스).

**Integration (`integration_test/` 신규):**
- `integration_test/msa_chapter_flow_test.dart` — 중앙 홀 → 아키텍처 분관 → 책장 → phase4-step1 챕터 → 이론 탭 → 시뮬레이터 탭 → 정답 조립 → 완료 보상 → `PlayerProgress.completedChapters` 반영 확인. 탭 전환 시 조립 상태 보존 확인.

**CRITICAL 회귀 테스트 (IRON RULE):**
- 위 `book_reader_simulator_routing_test.dart`의 CodeStep 라우팅 케이스.
- `test/data/models/book_model_simulator_test.dart`의 CodeStepConfig.fromJson 하위호환 케이스.
- 이 두 케이스는 sealed union 리팩터 PR에 함께 머지되어야 함. 분리 금지.

**의존성 추가:** `pubspec.yaml` dev_dependencies에 `integration_test: sdk: flutter` 추가.

---

## 10. 성공 기준

Phase 2는 다음이 모두 충족되어야 성공:

1. MSA 3챕터에서 구조 조립 시뮬레이터가 완주 가능 (정답 → 완료 처리).
2. **대조군 장치 (Outside Voice 반영 — T2):** 3챕터 중 **1챕터는 게임 시뮬레이터 금지, 마크다운 원문으로만 일주일 학습**. 나머지 2챕터는 게임 시뮬레이터 + 이론 탭 병행. 어느 챕터를 대조군으로 둘지는 Task 2-1 착수 시점에 결정(편향 방지용으로 작성 전에 정함).
3. 일주일 뒤 3챕터 모두에 대해 다음 3개 문장을 본인이 작성:
   - a. "이 챕터에서 **지금 기억나는 핵심 개념** 3가지"
   - b. "다시 설명하라면 **손으로 다이어그램**을 어떻게 그릴지 1문단"
   - c. "어떤 학습 방식이었나 (게임 / 마크다운)"
4. (c)를 모르는 상태에서 (a),(b)의 밀도를 비교. 대조군(마크다운)이 게임 2챕터보다 같거나 높으면 **가치 명제 실패 신호**.
5. (a)(b)가 유의미하게 게임 쪽이 진하면 Approach B(픽셀아트 업그레이드) + 추가 카테고리로 확장.
6. 결과가 모호하면 Approach C(진단 모드) 또는 다른 시뮬레이터 타입(SQL 실습)으로 피벗.

> **주의 (T2 맥락):** Ikea effect + confirmation bias를 완전 제거할 수 없으므로 위 절차도 "엄격한 실험"이 아니라 "1인 비교 체험"임을 인지한 채 결과 해석. 완전 통제 실험은 4단계(사내 교육)로 넘어갈 때의 과제.

---

## 11. 배포 계획

### 11.1 콘텐츠 빌드 파이프라인 수정
- `tools/content_builder.dart`: simulator 필드 분기 + **override JSON merge 로직 추가**.
  - `content/overrides/<category>/<chapter-id>.json` 존재 시 해당 챕터의 `simulator` 필드를 override로 교체.
  - 파일 없으면 기본값(`{type: codeStep, steps: []}`) 유지 + 경고 로그.
  - JSON 파싱 실패 시 `throw` → CI 빌드 중단.
- `content/overrides/` 디렉토리는 dol 레포에 포함. `docs-source/`(private submodule)는 건드리지 않음.

### 11.2 모바일 fallback (Outside Voice 반영 — T4)
Flutter Web의 `Draggable`/`DragTarget`은 모바일 브라우저에서 long-press + 스크롤 충돌 이슈. Phase 2 범위:
- `kIsWeb` + `MediaQuery` 터치 감지로 모바일 검출 → 시뮬레이터 탭에 "현재 모바일 브라우저는 이론 모드만 제공됩니다. 데스크톱에서 접속해주세요." 배너 표시.
- 모바일에서도 이론 탭은 정상 표시.
- GitHub Pages URL 모바일 접근은 그대로 허용, 기능 제한만.

### 11.3 CI 파이프라인 (Outside Voice 반영 — T6)
기존 `sync-and-deploy.yml`에 다음 추가:
- `flutter test` (unit + widget) — PR 게이트.
- `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/msa_chapter_flow_test.dart -d web-server` — **ChromeDriver 설정 필요**.
- GitHub Actions runner에 ChromeDriver setup step 추가 (`browser-actions/setup-chrome@v1` + chromedriver 매칭 버전).
- integration_test 실패 시 gh-pages 배포 중단.

### 11.4 배포 URL
- GitHub Pages URL 유지: `https://public-project-area-oragans.github.io/dol/`

---

## 12. 의존성

- Phase 1 전 시스템(Flame 씬, NPC 대화, 퀴즈 오버레이, Gist 저장).
- `docs-source/MSA/` 원본 마크다운 46챕터.
- Issue #13 (Task 12 ASCII 다이어그램 정렬)은 Phase 2와 독립적으로 진행 가능 — 차단 요소 아님.
- `flutter_markdown`, Riverpod, freezed는 기존 의존성 그대로.

---

## 13. 오픈 질문

1. ~~MSA 3챕터 후보~~ ✅ **해소** — 확정: `phase4-step1-api-gateway`, `phase4-step2-service-discovery`, `phase4-step4-resilience-patterns`.
2. ~~정답 연결 관계 JSON 스키마~~ ✅ **해소** — Task 2-0에서 스키마 확정 (섹션 9).
3. 그리드 캔버스 크기 (초기: 5×5 고정, 추후 확장 가능) — 첫 3챕터 작성 시 실용성 재검토.
4. 부분 정답 피드백 수준 — Task 2-3 구현 시점에 "노드 일치 / 엣지 일치 / 개별 연결 지적" 3단 중 어디까지 가져갈지 결정.
5. 대조군 챕터 선택 기준 — 3챕터 중 어느 것을 마크다운 전용으로 돌릴지 (섹션 10, T2 맥락). 편향 최소화 위해 **작성 전에** 제비뽑기 또는 가나다 순 첫 챕터로 사전 고정.
6. (plan-design-review Pass 7) 힌트 상세 — "완전 실패" 상태의 힌트 버튼이 정답 실루엣 1회 깜빡? 엣지 하나씩 공개? 힌트 사용 횟수 제한? Task 2-2 구현 시 결정.
7. (plan-design-review Pass 7) 챕터 완료 보상 연출 — QuestReward.xp는 Phase 1에서 숫자만 있음. 구조 조립 통과 시 톱니 회전·gold 파티클·NPC 대사 중 어느 조합? Task 2-2 구현 시.
8. (plan-design-review Pass 7) 팔레트 카테고리 그룹핑 — 6~8개 서비스 블록을 단순 리스트로 할지 Network/Data/Messaging 섹션으로 나눌지. 실제 블록 목록 확정 후 결정.

---

## 14. 다음 세션 Assignment (1주 내)

**본인이 다음 세션 시작 전에 해야 하는 *실제* 작업 (코드 아님, 콘텐츠 큐레이션):**

1. 확정된 3챕터 원문을 정독:
   - `docs-source/MSA/phase4-step1-api-gateway.md`
   - `docs-source/MSA/phase4-step2-service-discovery.md`
   - `docs-source/MSA/phase4-step4-resilience-patterns.md`
2. 각 챕터에서 "이 구조만 조립하면 챕터 핵심 이해 완료"라 할 만한 **노드 5~10개 + 엣지 5~12개**를 종이에 스케치.
3. 대조군 챕터 1개를 **미리** 선택 (제비뽑기 또는 가나다 순 첫 챕터). 이 챕터는 시뮬레이터 작성 금지.
4. Task 2-0 스키마에 맞춰 나머지 2챕터의 `content/overrides/msa/<chapter-id>.json`을 수기 초안(JSON 유효성은 Task 2-0 확정 후 재작성).

건너뛰면 Task 2-1 구현 단계에서 그래프가 "챕터 핵심 이해와 무관한 구조"가 될 위험.

---

## 15. 관찰한 것 (What I noticed)

office-hours 세션에서 사용자가 드러낸 사고 패턴:

- **"완성도 20% 이하라 어느정도 계획에서 수립한 내용이 만들어져야 검증 가능"** — 플랫폼형 사고의 교과서적 프레임. 작은 슬라이스로 가치 증명이 가능한 프로젝트인데도 전체를 더 만들어야 한다는 쪽으로 기본 기울어짐. 이건 Phase 2의 MVP 범위 결정에 가장 큰 영향을 준 답변.
- **"반대 — 구조 조립이 먼저"** — P1에 반대 이유를 설명한 점이 좋음. "시각적 임팩트가 크다"라는 실제 프로덕트 감각. 이 근거는 Approach A가 "게임답지 않음" 단점을 가진다는 평가와 맞물려 A→B 단계 접근으로 이어짐.
- **"MySQL은 본인이 이미 익숙해 학습 체감이 어렵다"** — 자기 자신을 1단계 타겟 사용자로 정직하게 진단. 이건 드문 자기 인식. 많은 개발자가 "내가 안 쓰는 것도 만들 수 있다"로 뛰어들어 실패함.
- **1→4→3 진화 경로를 숫자로 표현** — 시장 단계에 대한 구조화된 사고. 단순한 "게임 만들어보고 싶다"와 구분됨.

공통점: **이 사람은 장인적 완결성을 원함**. "80% 더 만들어야"가 두려움에서 나온 게 아니라 "끝까지 만든 뒤 보여주고 싶다"에서 나옴. Phase 2의 역할은 그 완결 욕구를 "전체 설계 완성" 대신 "1 슬라이스 완성 → 검증 → 재설계"의 싸이클로 재배치하는 것.

---

## 16. 외부 리뷰 요약 (Outside Voice — 2026-04-18)

plan-eng-review 완료 후 독립 Claude subagent(codex 미설치 환경의 fallback)에 의해 비판적 리뷰 수행. SEVERITY 6/10("진행 가능하나 보강 필요"). 6개 지적 중 본 문서 반영 결과:

| ID | 지적 | 결정 | 반영 위치 |
|----|------|------|----------|
| T1 | sealed union이 3챕터 MVP에 과잉 | **기각 (A 유지)** — 장기 구조 견실함 우선 | 섹션 6 P1, 섹션 9 Task 2-0 유지 |
| T2 | 자기 관찰 검증의 Ikea effect | **수용** — 대조군 장치 추가 | 섹션 10 성공 기준, 섹션 13 Q5 |
| T3 | Saga 챕터 실제 목차 불일치 | **수용** — Resilience Patterns로 교체 | 섹션 5, 섹션 7 Approach A, 섹션 14 |
| T4 | 모바일 터치 문제 누락 | **수용** — 모바일 fallback 명시 | 섹션 11.2 |
| T5 | override JSON 스키마는 Task 0 | **수용** — Task 2-0 신설 | 섹션 9 Task 2-0 |
| T6 | integration_test ChromeDriver 설정 | **원안 유지 (B)** — CI에 ChromeDriver 추가 | 섹션 11.3 |

User Sovereignty 원칙 적용: 각 tension은 AskUserQuestion으로 사용자가 결정. 외부 의견은 **정보** 제공이며 자동 채택 금지.

---

## 17. Task Workflow (Phase 2 Sprint 실행 계획)

Phase 2 설계 문서를 기반으로 한 실행 가능한 타임라인. 4주 Sprint (CC+gstack 기준). 매일 단위가 아니라 **의존성 단위**로 해석 (본인 가용 시간에 따라 압축/확장 가능).

### 17.1 타임라인

| 주차 | Task | 내용 | 전제/게이트 |
|------|------|------|------------|
| **W1 D1** | Task 2-0a ✅ | characterization regression test 7/7 PASS | — |
| **W1 D2** | Task 2-0b ✅ | sealed union 리팩터 + 신규 freezed 서브모델 (GridSize·GridPos·PaletteItem·AssemblyNode·AssemblyEdge·AssemblySolution·PartialFeedback·CodeStepConfig·StructureAssemblyConfig) + build_runner. `SimulatorType` enum 제거. Gate 1 PASS (12/12) | ✅ **완료** |
| **W1 D3** | Task 2-0c ✅ | `tools/content_builder.dart`의 `applyOverride()` 함수 추가 + MSA 3 스캐폴드 JSON 생성. content_builder 실행해 `content/books/msa/book.json`에 structureAssembly 3챕터 주입 완료 | ✅ **완료** (18/18 tests, 0 errors) |
| **W1 D4** | Assignment | 3챕터 docs-source 정독 + 정답 그래프 종이 스케치 + **대조군 챕터 사전 고정**(가나다 순 첫 챕터) | **코드 아님 (콘텐츠 큐레이션)** |
| **W1 D5** | Task 2-1 | 2챕터 override JSON 작성 (대조군 제외) — 스키마에 실제 노드·엣지 주입 | Assignment 완료 |
| **W2 Track A** | Task 2-3 | `lib/domain/usecases/graph_validator.dart` pure Dart 구현 + unit test 7 케이스 | Task 2-0b 완료 (모델 존재) |
| **W2 Track B** | Task 2-2 | `lib/presentation/simulators/structure_assembly_simulator.dart` (wireframe + 6 state + 11단계 journey + a11y 전체) | Task 2-0b 완료 |
| **W3 D1-2** | Task 2-4 + 2-5 | `book_reader_screen.dart` sealed union switch 라우팅 + 계측 로그 (Hive Box 재활용) | Track A, B 완료 |
| **W3 D3** | Task 2-6 | widget test 10 + integration test 1 (`integration_test/msa_chapter_flow_test.dart`) | Task 2-4 완료 |
| **W3 D4** | CI | `sync-and-deploy.yml`에 ChromeDriver setup + `flutter drive` 단계 추가 | Task 2-6 로컬 PASS |
| **W3 D5** | 통합 | 전체 회귀 게이트 + 첫 프로덕션 배포 | **게이트:** 회귀 7/7 + 신규 테스트 전부 PASS + CI 통과 |
| **W4 D1-7** | 실사용 | 게임 2챕터 + 마크다운 대조군 1챕터 (성공 기준 섹션 10 절차) | 배포 완료 |
| **W4 틈새 (병렬)** | ★ Issue #13 | Phase 1 잔여 (flutter_markdown ASCII 다이어그램 정렬). 실사용 1주 중 CC 작업 가능 시간에 끼워 처리. Phase 2 UI와 충돌 없음 | — |
| **W4 D7** | 회고 | 대조군 vs 게임 기억·다이어그램 밀도 비교 → **분기 결정** | 실사용 1주 종료 |
| **W4 D7+** | ★ Notify workflow (조건부) | 회고 결과가 "기억에 남는다"면 `develop-study-documents`에 `notify-game.yml` + `DOL_DISPATCH_TOKEN` secret 추가. "애매/방해"면 보류 | **조건:** 확장 방향 결정 |

### 17.2 의존성 그래프

```
2-0a(✅) → 2-0b ───┬─→ 2-0c ──→ 2-1 ────────┐
                   │                          │
                   ├─→ 2-3 (Track A) ─────────┤
                   │                          │
                   └─→ 2-2 (Track B) ─────────┤
                                              │
                                              ▼
                                          2-4 + 2-5
                                              │
                                              ▼
                                           2-6 + CI
                                              │
                                              ▼
                                          통합 배포
                                              │
                                              ▼
                     Issue #13 ◄─── 실사용 1주 ────▶ 회고
                      (병렬)                              │
                                                         ▼
                                    (조건부) Notify workflow
                                              │
                                              ▼
                                 Approach B / C / SQL 피벗 결정
```

### 17.3 회귀 게이트 체크포인트 (2회)

| 체크포인트 | 위치 | 합격 조건 | 불합격 시 |
|-----------|------|----------|----------|
| **Gate 1** | W1 D2 직후 (sealed union 리팩터 후) | `test/data/models/book_model_regression_test.dart` 7/7 PASS | 원인 파악 전까지 D3 이후 **진행 중단**. `--delete-conflicting-outputs` 재실행, fromJson unionKey 매핑 재검토 |
| **Gate 2** | W3 D5 (통합 배포 직전) | 회귀 7/7 + 신규 unit 14 + widget 13 + integration 1 + CI 전부 PASS | 프로덕션 배포 **금지**. 실패 테스트 해결 후 재시도 |

### 17.4 Issue #13 & Notify workflow 배치 근거

**Issue #13 (Task 12 ASCII 다이어그램) — W4 틈새:**
- Phase 1의 flutter_markdown 정렬 잔업. 구조 조립 시뮬레이터 UI와 충돌 없음.
- W4 실사용 1주간은 CC가 대기하는 시간 → 독립 잔업을 밀어넣기 정확한 자리.
- 이 작업은 `lib/presentation/widgets/theory_card.dart`의 마크다운 렌더링 개선이 중심. Task 2-2/2-3과 파일 겹침 없음.

**Notify workflow (선택) — W4 D7+ 조건부:**
- 회고 결과가 **"기억에 남는다"** → 확장 결정 → docs-source 변경 빈도 증가 예상 → 자동 재배포 필요 → notify 도입.
- 회고 결과가 **"애매/오히려 방해"** → 피벗 준비 → docs-source 구조 자체가 달라질 가능성 → 수동 유지.
- **현재 시점에서 Notify 조기 도입은 투자 낭비.** 변경 빈도 낮고, 자동화가 잘못된 방향 반복 배포를 굳힐 위험.

### 17.5 병렬성 지침

- **Track A(GraphValidator)와 Track B(Simulator widget)**는 완전 독립 — Track A는 `lib/domain/usecases/`, Track B는 `lib/presentation/simulators/`. 파일 겹침 0, 의존성 양방향 없음. 별도 브랜치(`feature/task-2-3-validator`, `feature/task-2-2-simulator`)로 동시 진행 가능.
- **Task 2-1 콘텐츠 JSON**은 Track A·B 완성도와 무관. Assignment 완료 즉시 2-1 작성 시작 가능.
- **Issue #13**은 Phase 2 전체와 병렬 가능. Week 1~3 중 어디에 끼워도 됨. 다만 회귀 게이트와 충돌 피하려면 W4 권장.

### 17.6 Week 4 회고 분기 결정 트리

```
실사용 1주 종료
    │
    ▼
기억·다이어그램 밀도 비교 (섹션 10 절차)
    │
    ├─ 게임 > 마크다운 → 가치 명제 확증
    │                    ├─ Notify workflow 도입
    │                    ├─ Approach B 업그레이드 (Flame 픽셀아트 캔버스)
    │                    └─ 추가 카테고리 1개 확장 후보 검토
    │
    ├─ 게임 ≈ 마크다운 → 보강 실험
    │                    ├─ 보상 엔진(XP·뱃지) 추가로 리텐션 실험
    │                    └─ Approach C(진단 모드) 시도
    │
    └─ 게임 < 마크다운 → 메커니즘 피벗
                         ├─ SQL 실습 시뮬레이터로 전환
                         └─ 원본 메커니즘 가치 명제 재설계 (Phase 3 재시작)
```

### 17.7 작업 환경 체크리스트 (각 세션 시작 전 확인)

```bash
# 1. 브랜치 확인
git branch --show-current

# 2. 의존성 준비
flutter pub get

# 3. 회귀 가드 항상 실행
flutter test test/data/models/book_model_regression_test.dart

# 4. (리팩터 세션) build_runner 실행
dart run build_runner build --delete-conflicting-outputs
```

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | **CLEAR (PLAN)** | Arch 3 / Quality 1 / Test gap 22 → Task 2-6 반영 / Perf 0. 2 CRITICAL regression 설계 박힘. |
| Outside Voice | Claude subagent | Independent 2nd opinion | 1 | **ISSUES (6 → 5 수용 / 1 기각)** | SEVERITY 6/10. 섹션 16 참조. |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | **CLEAR (FULL)** | score 3/10 → 9/10. 9 decisions made, 3 deferred. Wireframe + Journey + a11y 전체 박힘. |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**CROSS-MODEL:** plan-eng-review는 sealed union 채택(A). Outside Voice는 과잉으로 반박(T1). 사용자는 A 유지 결정 — 장기 구조 우선. 나머지 5개 tension은 문서에 반영.

**UNRESOLVED:** 0

**VERDICT:** ENG CLEARED — 구현 착수 가능. Design/CEO/DX 리뷰는 선택 사항. 다음 단계는 Task 2-0 (override JSON 스키마) → Task 2-1 (3챕터 콘텐츠 초안).
