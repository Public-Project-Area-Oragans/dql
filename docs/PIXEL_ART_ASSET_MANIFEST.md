# PixelLab AI 에셋 매니페스트
## Asset Manifest & Architecture Spec — Flame + Flutter 통합 규격

> **버전**: v1.0  
> **최종 수정일**: 2026-04-18  
> **상위 문서**: [`PIXEL_ART_ASSET_BIBLE.md`](./PIXEL_ART_ASSET_BIBLE.md) v1.0  
> **문서 목적**: Bible의 스타일 기준을 Flame+Flutter 하이브리드 아키텍처에 적용하기 위한 **구현 규격**

---

## 📌 이 문서의 위치

| 문서 | 역할 | 질문 |
|---|---|---|
| **ASSET BIBLE** (상위) | 스타일 헌법 | "어떻게 그리는가?" |
| **ASSET MANIFEST** (이 문서) | 아키텍처 연결 규격 | "무엇을 / 어디에 / 어떤 형식으로?" |

**두 문서 모두 통과해야 에셋이 유효하다.**
- Bible 위반 → 스타일 드리프트 (예: 팔레트 벗어남)
- Manifest 위반 → 코드에서 로드·렌더링 불가 (예: 프레임 크기 불균일로 `SpriteSheet` 깨짐)

### 표기 규약 (Bible과 동일)
- 🔒 **Locked** : 변경 시 이 문서 버전업
- ⚙️ **Tunable** : 카테고리 단위 조정 가능
- ❌ : 금지 사항

---

## §1. 레이어별 에셋 책임 (Flame vs Flutter)

### 1.1 책임 분리 원칙 🔒

| 레이어 | 담당 에셋 | 대표 오브젝트 |
|---|---|---|
| **Flame Layer** | 월드 공간의 모든 것 | 배경, NPC, 정령·골렘, 월드 오브젝트, 파티클, 타일맵 |
| **Flutter UI Layer** | 화면 공간의 모든 것 | 대화창, 버튼, 프레임, 아이콘, 모달, 책 뷰어 |

### 1.2 경계 규칙 🔒
- **클릭·터치 이벤트**: Flame의 `HasTappables` / `TapCallbacks` 믹스인이 1차 감지 → Riverpod 상태 변경 → Flutter 오버레이 렌더
- **좌표계 분리**: Flame은 월드 좌표 (타일 기준), Flutter는 화면 좌표 (논리 px)
- **에셋 중복 로드 금지** ❌ : 동일 PNG를 두 레이어에 중복 로드하지 않는다. 하나의 에셋은 하나의 레이어에서만 메모리에 존재.

### 1.3 경계 예외
| 예외 | 이유 | 구현 |
|---|---|---|
| 타이틀 로고 | Flame 씬 로드 전 표시 필요 | Flutter 정적 이미지 |
| 페이드 인/아웃 | 두 레이어를 동시에 덮어야 함 | Flutter `AnimatedOpacity` 오버레이 |
| 포털 하이라이트(hover) | Flame의 월드 좌표를 Flutter가 알아야 함 | Flame이 좌표 publish → Flutter가 `Stack` 으로 오버레이 렌더 |

---

## §2. 프로젝트 분관 정의 (Bible §1.3 적용판) 🔒

Bible v1.0 §1.3에 나열된 6개 분관 중, 이 프로젝트는 **4개 분관만** 사용한다.

| 분관 ID | 기술 분야 | NPC | 지배색 | 악센트 |
|---|---|---|---|---|
| `backend_wing` | 백엔드·API | 마법사 (Wizard) | 갈색 + 구리 + 녹색 | **Green Steam** |
| `database_wing` | DB·자료구조 | 연금술사 (Alchemist) | 갈색 + 호박색 | **Amber Warm** |
| `frontend_wing` | 프론트엔드·UI | 기계공 (Mechanic) | 갈색 + 금 + 시안 | **Prism** (※) |
| `architecture_wing` | 아키텍처·설계 | 건축가 (Architect) | 갈색 + 금 (강조 없음) | **Pure Gold** (※) |

### 2.1 신규 분관 팔레트 해석

**※ Prism 악센트 (Frontend)** — Bible 팔레트에 시안이 없으므로, **Steam Verdigris `#3e7a5a` + Glowing Lilac `#b479e8`** 를 인접 배치해서 프리즘·스테인드글라스 느낌을 낸다. **새 색상 추가 금지.**

**※ Architecture Wing은 Bible에 없던 분관**이다. 마법·증기 악센트 없이 **순수한 갈색+금**으로 "청사진·설계도" 분위기를 만든다. 차별화 포인트는 색이 아니라 **기하학적 패턴**(그리드·컴퍼스·직각자·골격 모형).

### 2.2 분관별 핵심 모티프 🔒

| 분관 | 시각적 핵심 요소 |
|---|---|
| Backend | 수증기 배관, 압력 밸브, 거대 기어, 녹색 증기 분출구 |
| Database | 카탈로그 서랍장, 황동 명판, 인장, 호박색 램프, 빼곡한 카드 |
| Frontend | 스테인드글라스 창, 프리즘, 거울 진열장, 다색 유리병 |
| Architecture | 청사진 두루마리, 컴퍼스·직각자, 골격 모형, 건축 미니어처 |

---

## §3. 에셋 타입 규격

### 3.1 정적 스프라이트 (Single Frame) 🔒
단일 PNG, 투명 배경, Bible §3.2 해상도 준수.

| 용도 | 해상도 | 모델 | no_background |
|---|---|---|---|
| 오브젝트 (소품·도구) | 32×32 or 64×64 | BitForge | `True` |
| UI 아이콘 | 32×32 | BitForge | `True` |
| 정적 NPC (모션 없는 장면) | 64×96 | BitForge | `True` |
| 초상화 (대화용) | 64×64 | BitForge | `True` |

### 3.2 애니메이션 스프라이트 시트 (Flame 호환) 🔒

**Flame `SpriteSheet` 클래스 호환 레이아웃.** 프레임은 **가로 일렬**로 배치.

```
┌──────┬──────┬──────┬──────┐
│  F0  │  F1  │  F2  │  F3  │   ← 4프레임 × 64×64 → 시트 256×64
└──────┴──────┴──────┴──────┘
```

#### 기술 규격 🔒
- **프레임 크기 균일** ❌ 1px라도 차이 나면 Flame 렌더링 깨짐
- **프레임 사이 패딩 0px** ❌ 여백 절대 금지
- **가로 배열 원칙** (Flame `SpriteAnimation.spriteList` 기본)
- **방향별 스프라이트는 행(row)으로** — 4방향 × 4프레임 = `256×256` 시트

#### 애니메이션 표준 프레임 수 🔒

| 애니메이션 | 프레임 수 | FPS | 루프 | 비고 |
|---|---|---|---|---|
| `idle` | 4 | 4 | ✅ | 대기 |
| `walk` | 4 | 8 | ✅ | 걷기 |
| `talk` | 2 | 4 | ✅ | 입·손 제스처 |
| `wave` | 4 | 6 | ❌ | 손 인사 (1회) |
| `interact` | 4 | 8 | ❌ | 상호작용 (1회) |
| `float` | 6 | 4 | ✅ | 정령 상하 부유 |
| `glow` | 4 | 3 | ✅ | 책장·포털 발광 |

#### PixelLab 생성 플로우 🔒

```
1. create_character(description, n_directions=4)
   → 방향별 정지 스프라이트 획득
2. animate_character(character_id, animation="walk")
   → walk 시트 생성
3. 후처리 (ImageMagick 또는 Python Pillow)
   → Flame 호환 레이아웃으로 재조립 (패딩 제거 + 가로 병합)
```

### 3.3 Wang 타일셋 (Flame Tiled 호환) 🔒

**바닥·벽 타일은 `create_tileset` 으로 생성.** Tiled 에디터로 `.tmx` 맵 제작 후 Flame `TiledComponent` 로드.

- 각 타일: **32×32**
- Wang 2-코너 방식 → 16 타일 (최소)
- Wang 3-코너 방식 → 256 타일 (풍부)
- 파일 포맷: PNG (투명 배경 없음)

#### 분관별 타일셋 🔒

| 분관 | 타일셋 ID | 구성 | Wang 방식 |
|---|---|---|---|
| 공통 | `tileset_common_floor` | 바닥 + 엣지 | 2-코너 |
| Backend | `tileset_backend_wall` | 증기관 있는 벽 | 2-코너 |
| Database | `tileset_db_wall` | 서랍장 벽 | 2-코너 |
| Frontend | `tileset_frontend_wall` | 스테인드글라스 벽 | 2-코너 |
| Architecture | `tileset_arch_wall` | 청사진 벽 | 2-코너 |

### 3.4 9-Slice 프레임 (UI 프레임·버튼) 🔒

**Flutter/Flame 양쪽 공용.** 크기 조절 가능한 프레임.

#### 구조

```
┌──┬──────────┬──┐
│C1│    E1    │C2│   ← 8px 코너 + 반복 엣지 + 8px 코너
├──┼──────────┼──┤
│E4│  CENTER  │E2│   
├──┼──────────┼──┤
│C4│    E3    │C3│
└──┴──────────┴──┘
```

#### 규격 🔒
- **기본 크기: 128×64** (Bible §3.2)
- **코너 크기: 8×8 고정** ❌ 변경 금지
- **엣지**: 중앙 1~16px 반복 패턴 허용 ⚙️
- **중앙**: 빈 칸 또는 반투명 `rgba(45, 32, 21, 0.85)` (= `#2d2015` + alpha)

#### 필요 9-Slice 풀

| ID | 용도 | 톤 |
|---|---|---|
| `ui_frame_dialog` | 대화창 | 갈색 + 금 테두리 |
| `ui_frame_panel` | 인벤토리·메뉴 패널 | 갈색 기조 |
| `ui_frame_quest` | 퀘스트 카드 | 갈색 + 호박색 |
| `ui_frame_book` | 책 열람 페이지 | 갈색 + Parchment |
| `ui_frame_code_terminal` | 시뮬레이터 코드창 | 어두운 갈색 + 녹색 커서 |
| `ui_button_primary` | 기본 버튼 (idle) | 갈색 + 금 |
| `ui_button_primary_hover` | hover | 금색 강조 |
| `ui_button_primary_pressed` | pressed | 어두운 갈색 |
| `ui_button_disabled` | 비활성 | 회색조 갈색 |
| `ui_progressbar_empty` | 프로그레스 빈 게이지 | 어두운 갈색 |
| `ui_progressbar_fill` | 프로그레스 채움 | 금색 |

#### 구현 힌트
- **Flame**: `NineTileBoxComponent`
- **Flutter**: `DecoratedBox` + `BoxDecoration.border` 또는 `nine_patch_image` 패키지

### 3.5 파티클·VFX 아틀라스 🔒

#### 단일 입자 규격
- 입자 크기: **16×16** ⚠️ (Bible §3.2 해상도 표의 **유일한 예외**)
- 아틀라스: 4×4 그리드 = 64×64 (16프레임 시퀀스)
- 프레임별 alpha 그라디언트 (spawn → peak → despawn)

#### 파티클 풀 🔒

| ID | 용도 | 색 |
|---|---|---|
| `vfx_dust_ambient` | 상시 떠다니는 도서관 먼지 | Parchment `#e8dcc4` |
| `vfx_steam_green` | Backend 증기 분출 | Verdigris `#3e7a5a` |
| `vfx_magic_purple` | 마법 파동·주문 시전 | Arcane Purple `#7b3ea8` |
| `vfx_spark_gold` | 보상·레벨업 반짝임 | Polished Gold `#d4a845` |
| `vfx_pageflip_parchment` | 책 페이지 넘김 | Parchment |
| `vfx_correct_sparkle` | 퀴즈 정답 연출 | Gold + Parchment |
| `vfx_wrong_smoke` | 퀴즈 오답 연출 | Void Violet `#3a1a55` |

### 3.6 배경 풀샷 (Parallax 3층) ⚙️

**Flame `ParallaxComponent` 를 사용하는 다층 배경.** 깊이감과 움직임 생성.

| 레이어 | 해상도 | 내용 | 스크롤 속도 |
|---|---|---|---|
| far | 256×144 | 원경 (거대 기어, 멀리 보이는 천장) | 0.3x |
| mid | 256×144 | 중경 (책장, 샹들리에) | 0.6x |
| near | 256×144 | 근경 (기둥, 전경 책상) | 1.0x |

- `no_background=False` 로 생성
- **PixFlux** 사용 (앵커 참조 불가 → 생성 후 **BitForge inpainting 으로 톤 보정 필수**)
- 레이어별로 **분리 생성** (한 번에 모든 걸 담지 말 것)

---

## §4. 애니메이션 상태 매트릭스 🔒

### 4.1 NPC (마법사·연금술사·기계공·건축가)

| 상태 | 필수? | 프레임 | 방향 | PixelLab 도구 |
|---|---|---|---|---|
| `idle` | ✅ | 4 | 정면 + 측면(좌/우) | `create_character` + `animate_character` |
| `talk` | ✅ | 2 | 정면만 | `animate_character` |
| `wave` | ⚙️ | 4 | 정면만 | `animate_character` |

> **방향 처리**: 측면은 **좌측 1세트만 생성 후 Flame에서 `flipHorizontallyAroundCenter()` 로 우측 미러링**. 생성 비용 절반 절약.

### 4.2 플레이어 아바타 (옵션)

| 상태 | 필수? | 프레임 | 방향 |
|---|---|---|---|
| `idle` | ✅ | 4 | 4방향 (N/E/S/W) |
| `walk` | ✅ | 4 | 4방향 |
| `interact` | ✅ | 4 | 정면만 |

### 4.3 정령·골렘 (분관 안내자, 각 분관당 1체)

| 상태 | 필수? | 프레임 | 비고 |
|---|---|---|---|
| `float` | ✅ | 6 | 상하 부유 루프 (지속 표시) |
| `interact` | ✅ | 4 | 책 건네주기 (1회) |
| `vanish` | ⚙️ | 4 | 소환 해제 (1회) |

### 4.4 월드 오브젝트

| 종류 | 상태 | 프레임 | 비고 |
|---|---|---|---|
| 퀘스트 게시판 | `idle`(깃발 펄럭) | 4 | 루프 |
| 분관 입구 문 | `closed` / `opening` / `opened` | 1 / 4 / 1 | 3-stage |
| 책장 | `static` / `glow` | 1 / 4 | glow는 상호작용 가능 시 루프 |
| 부유 책 | `float` | 6 | 루프 |

---

## §5. 화면별 에셋 매니페스트

각 화면에 필요한 에셋을 **완전히 열거**. 누락 시 해당 화면 구현 불가.

### 5.1 타이틀·스플래시 화면

| Asset ID | 카테고리 | 해상도 | 레이어 |
|---|---|---|---|
| `ui_logo_title` | 정적 일러스트 | 512×256 | Flutter |
| `env_title_bg` | 배경 풀샷 | 256×144 | Flutter (확대 표시) |
| `ui_button_primary` | 9-slice | 128×64 | Flutter |
| `ui_icon_github` | 아이콘 | 32×32 | Flutter |
| `vfx_dust_ambient` | 파티클 | 64×64 (시트) | Flutter 오버레이 |

**에셋 수: 5**

### 5.2 중앙 홀

| Asset ID | 카테고리 | 해상도 | 레이어 |
|---|---|---|---|
| `env_mainhall_bg_far` | Parallax | 256×144 | Flame |
| `env_mainhall_bg_mid` | Parallax | 256×144 | Flame |
| `env_mainhall_bg_near` | Parallax | 256×144 | Flame |
| `tileset_common_floor` | Wang 타일셋 | 128×128 (16타일) | Flame |
| `obj_door_backend` | 정적 + glow | 64×96 + 4프레임 | Flame |
| `obj_door_database` | 정적 + glow | 64×96 + 4프레임 | Flame |
| `obj_door_frontend` | 정적 + glow | 64×96 + 4프레임 | Flame |
| `obj_door_architecture` | 정적 + glow | 64×96 + 4프레임 | Flame |
| `char_wizard_idle` | 시트 | 256×96 (4프레임) | Flame |
| `char_alchemist_idle` | 시트 | 256×96 | Flame |
| `char_mechanic_idle` | 시트 | 256×96 | Flame |
| `char_architect_idle` | 시트 | 256×96 | Flame |
| `obj_quest_board` | 시트 | 384×96 (4프레임, 96×96) | Flame |
| `vfx_dust_ambient` | 파티클 | 64×64 | Flame |
| `ui_highlight_interact` | 하이라이트 링 | 96×112 | Flame |

**에셋 수: 15**

### 5.3 분관 내부 (× 4 분관 복제)

분관 ID를 `{wing}` 으로 표기 (`backend_wing` / `database_wing` / `frontend_wing` / `architecture_wing`).

| Asset ID | 카테고리 | 해상도 | 레이어 |
|---|---|---|---|
| `env_{wing}_bg_far` | Parallax | 256×144 | Flame |
| `env_{wing}_bg_mid` | Parallax | 256×144 | Flame |
| `env_{wing}_bg_near` | Parallax | 256×144 | Flame |
| `tileset_{wing}_wall` | Wang 타일셋 | 128×128 | Flame |
| `obj_{wing}_bookshelf` | 정적 + glow | 64×96 + 4프레임 | Flame |
| `obj_{wing}_desk` | 정적 | 64×64 | Flame |
| `char_{wing}_npc_talk` | 시트 | 128×96 (2프레임) | Flame |
| `char_{wing}_spirit_float` | 시트 | 192×32 (6프레임, 32×32) | Flame |
| `char_{wing}_spirit_interact` | 시트 | 128×32 (4프레임) | Flame |
| `obj_{wing}_floating_book` | 시트 | 192×32 (6프레임) | Flame |

**에셋 수: 10 × 4 분관 = 40**

### 5.4 대화 시스템

| Asset ID | 카테고리 | 해상도 | 레이어 |
|---|---|---|---|
| `ui_frame_dialog` | 9-slice | 128×64 (가변) | Flutter |
| `ui_portrait_wizard` | 초상화 | 64×64 | Flutter |
| `ui_portrait_alchemist` | 초상화 | 64×64 | Flutter |
| `ui_portrait_mechanic` | 초상화 | 64×64 | Flutter |
| `ui_portrait_architect` | 초상화 | 64×64 | Flutter |
| `ui_portrait_player` | 초상화 | 64×64 | Flutter |
| `ui_button_dialog_choice` | 9-slice | 128×32 | Flutter |
| `ui_icon_continue_arrow` | 시트 | 64×16 (4프레임) | Flutter |

**에셋 수: 8**

### 5.5 이론 뷰어 (책 UI)

| Asset ID | 카테고리 | 해상도 | 레이어 |
|---|---|---|---|
| `ui_frame_book_left` | 9-slice | 256×192 | Flutter |
| `ui_frame_book_right` | 9-slice | 256×192 | Flutter |
| `ui_frame_book_spine` | 정적 | 16×192 | Flutter |
| `ui_frame_code_block` | 9-slice | 128×64 | Flutter |
| `ui_icon_bookmark` | 아이콘 | 32×32 | Flutter |
| `ui_icon_prev_page` | 아이콘 | 32×32 | Flutter |
| `ui_icon_next_page` | 아이콘 | 32×32 | Flutter |
| `vfx_pageflip_parchment` | 파티클 | 64×64 | Flutter |

**에셋 수: 8**

### 5.6 인터랙티브 시뮬레이터 (4종)

#### (a) 코드 스텝 실행 시뮬레이터

| Asset ID | 카테고리 | 해상도 |
|---|---|---|
| `ui_frame_code_terminal` | 9-slice | 256×192 |
| `ui_icon_play` | 아이콘 | 32×32 |
| `ui_icon_pause` | 아이콘 | 32×32 |
| `ui_icon_step_forward` | 아이콘 | 32×32 |
| `ui_icon_reset` | 아이콘 | 32×32 |
| `vfx_step_highlight` | 파티클 | 64×64 |

#### (b) 구조 조립 (드래그&드롭)

| Asset ID | 카테고리 | 해상도 |
|---|---|---|
| `ui_block_draggable_frame` | 9-slice | 128×48 |
| `ui_slot_empty` | 9-slice | 128×48 |
| `ui_slot_filled` | 9-slice | 128×48 |
| `ui_icon_drag_handle` | 아이콘 | 16×16 |
| `vfx_snap_gold` | 파티클 | 64×64 |

#### (c) 흐름 추적 (Request/Data Flow)

| Asset ID | 카테고리 | 해상도 |
|---|---|---|
| `obj_flow_node` | 정적 | 64×64 |
| `ui_flow_arrow_h` | 9-slice (가로) | 64×16 |
| `ui_flow_arrow_v` | 9-slice (세로) | 16×64 |
| `vfx_packet_travel` | 파티클 | 64×64 |

#### (d) SQL 실습

| Asset ID | 카테고리 | 해상도 |
|---|---|---|
| `ui_frame_sql_input` | 9-slice | 256×64 |
| `ui_frame_sql_result_table` | 9-slice | 256×192 |
| `ui_icon_execute_sql` | 아이콘 | 32×32 |

**시뮬레이터 총 에셋 수: 18**

### 5.7 퀴즈 시스템

| Asset ID | 카테고리 | 해상도 |
|---|---|---|
| `ui_frame_quiz_card` | 9-slice | 256×192 |
| `ui_button_answer` | 9-slice | 128×48 |
| `ui_icon_correct` | 시트 | 128×32 (4프레임) |
| `ui_icon_wrong` | 시트 | 128×32 (4프레임) |
| `ui_icon_ox_o` | 아이콘 | 32×32 |
| `ui_icon_ox_x` | 아이콘 | 32×32 |
| `vfx_correct_sparkle` | 파티클 | 64×64 |
| `vfx_wrong_smoke` | 파티클 | 64×64 |

**에셋 수: 8**

### 5.8 인벤토리·진행도 패널

| Asset ID | 카테고리 | 해상도 |
|---|---|---|
| `ui_frame_panel` | 9-slice | 128×64 |
| `ui_slot_inventory` | 9-slice | 32×32 |
| `ui_icon_badge_complete` | 아이콘 | 32×32 |
| `ui_icon_progress_locked` | 아이콘 | 32×32 |
| `ui_icon_progress_unlocked` | 아이콘 | 32×32 |
| `ui_icon_progress_in_progress` | 아이콘 | 32×32 |
| `ui_progressbar_empty` | 9-slice | 128×16 |
| `ui_progressbar_fill` | 9-slice | 128×16 |

**에셋 수: 8**

### 5.9 퀘스트 게시판·목록

| Asset ID | 카테고리 | 해상도 |
|---|---|---|
| `ui_frame_quest` | 9-slice | 256×128 |
| `ui_icon_quest_main` | 아이콘 | 32×32 |
| `ui_icon_quest_side` | 아이콘 | 32×32 |
| `ui_icon_quest_daily` | 아이콘 | 32×32 |
| `ui_icon_reward_gold` | 아이콘 | 32×32 |
| `ui_icon_reward_exp` | 아이콘 | 32×32 |
| `ui_icon_reward_book` | 아이콘 | 32×32 |

**에셋 수: 7**

### 5.10 씬 전환 효과

PixFlux로 개별 프레임 생성 후 Flame `SpriteAnimation` 으로 조립.

| Asset ID | 카테고리 | 해상도 |
|---|---|---|
| `vfx_scene_fade_gear` | 전체화면 시퀀스 | 256×144 × 12 |
| `vfx_scene_fade_pages` | 전체화면 시퀀스 | 256×144 × 12 |
| `vfx_scene_fade_smoke` | 전체화면 시퀀스 | 256×144 × 12 |

**에셋 수: 3**

---

## §6. 에셋 ID 체계 (코드 참조)

### 6.1 Dart 상수 클래스 (생성 예시)

```dart
// lib/core/assets/asset_ids.dart

class AssetIds {
  // ── Characters ────────────────────────────────────────
  static const charWizardIdle = 'characters/wizard/char_wizard_idle_v1.png';
  static const charAlchemistIdle = 'characters/alchemist/char_alchemist_idle_v1.png';
  static const charMechanicIdle = 'characters/mechanic/char_mechanic_idle_v1.png';
  static const charArchitectIdle = 'characters/architect/char_architect_idle_v1.png';

  // ── Environments ──────────────────────────────────────
  static const envMainhallBgFar = 'environments/main_hall/env_mainhall_bg_far_v1.png';
  static const envMainhallBgMid = 'environments/main_hall/env_mainhall_bg_mid_v1.png';
  static const envMainhallBgNear = 'environments/main_hall/env_mainhall_bg_near_v1.png';

  // ── UI ────────────────────────────────────────────────
  static const uiFrameDialog = 'ui/frames/ui_frame_dialog_v1.png';
  static const uiFrameBook = 'ui/frames/ui_frame_book_v1.png';
  static const uiButtonPrimary = 'ui/buttons/ui_button_primary_v1.png';

  // ── VFX ───────────────────────────────────────────────
  static const vfxDustAmbient = 'vfx/vfx_dust_ambient_v1.png';
  static const vfxMagicPurple = 'vfx/vfx_magic_purple_v1.png';
}
```

### 6.2 파일명 → Dart 상수 변환 규칙 🔒

Bible §8.2 파일명:
```
{카테고리약어}_{서브}_{이름}_{상태}_{방향}_v{N}.png
```

→ Dart 상수 (camelCase):
```
{카테고리}{서브}{이름}{상태}{방향}
```

**변환 예시**:
| 파일명 | Dart 상수 |
|---|---|
| `char_npc_mechanic_walk_e_v1.png` | `charNpcMechanicWalkE` |
| `ui_button_primary_hover_v1.png` | `uiButtonPrimaryHover` |
| `env_backend_floor_tile_01_v1.png` | `envBackendFloorTile01` |

### 6.3 `flutter_gen` 사용 권장 ⚙️
파일명 규칙이 일관적이므로 `flutter_gen` 패키지로 `Assets.images.characters.wizard.idle` 같은 타입-세이프 접근 자동 생성 권장.

---

## §7. 디렉토리 ↔ `pubspec.yaml` 매핑

### 7.1 선언 템플릿 🔒

```yaml
flutter:
  assets:
    # 🚫 스타일 앵커는 런타임 번들 제외 (개발 참조용)
    # - assets/_anchors/  ← 주석 처리

    # Characters
    - assets/characters/wizard/
    - assets/characters/alchemist/
    - assets/characters/mechanic/
    - assets/characters/architect/
    - assets/characters/player/
    - assets/characters/spirits/

    # Environments
    - assets/environments/main_hall/
    - assets/environments/backend_wing/
    - assets/environments/database_wing/
    - assets/environments/frontend_wing/
    - assets/environments/architecture_wing/

    # Objects
    - assets/objects/doors/
    - assets/objects/books/
    - assets/objects/furniture/
    - assets/objects/quest_board/

    # UI
    - assets/ui/frames/
    - assets/ui/buttons/
    - assets/ui/icons/
    - assets/ui/portraits/

    # VFX
    - assets/vfx/

    # Tilesets & Maps
    - assets/tilesets/
    - assets/maps/         # .tmx 파일
```

### 7.2 `_anchors/` 처리 🔒
- **런타임 번들 제외** (`pubspec.yaml` 에 선언 안 함)
- **BitForge 생성 시에만** `style_image_path` 로 참조
- **Git에는 반드시 포함** (`assets/_anchors/` 커밋 필수 — 재생성 때 필요)

---

## §8. 에셋 로딩 전략

### 8.1 3단계 로딩 🔒

| 단계 | 시점 | 대상 에셋 |
|---|---|---|
| **Preload** | 앱 시작 직후 | UI 프레임·아이콘·버튼, 타이틀 배경, 공용 파티클 |
| **SceneLoad** | 씬 진입 직전 | 해당 씬의 배경·NPC·타일셋·오브젝트 |
| **OnDemand** | 상호작용 발생 시 | 대화 초상화, 퀴즈 결과 VFX, 씬 전환 효과 |

### 8.2 Flame `Images` 캐시 관리

```dart
class BackendWingScene extends FlameGame {
  @override
  Future<void> onLoad() async {
    // SceneLoad 단계
    await images.loadAll([
      AssetIds.envBackendWingBgFar,
      AssetIds.envBackendWingBgMid,
      AssetIds.envBackendWingBgNear,
      AssetIds.tilesetBackendWall,
      AssetIds.charWizardIdle,
      // ...
    ]);
  }

  @override
  void onRemove() {
    // 씬 이탈 시 메모리 해제
    images.clear(AssetIds.envBackendWingBgFar);
    // ...
    super.onRemove();
  }
}
```

### 8.3 Web 빌드 최적화 ⚙️
- `flutter build web --web-renderer canvaskit --release`
- 에셋 압축: `pngquant --quality=90-100` (팔레트 16색 유지되는 범위에서)
- CDN 캐싱: GitHub Pages의 브라우저 캐시 헤더 활용

---

## §9. 반응형·렌더링 고려

### 9.1 렌더러 🔒
- **Flutter Web**: `--web-renderer canvaskit` (필수) — 픽셀아트 선명도 보장
- **모바일**: 기본 skia
- **필터링**: 모든 이미지 `FilterQuality.none` 🔒

```dart
Image.asset(
  AssetIds.charWizardIdle,
  filterQuality: FilterQuality.none,  // 🔒 필수 — 생략 시 블러 발생
);
```

```dart
// Flame에서
final sprite = await Sprite.load(
  AssetIds.charWizardIdle,
  srcPosition: Vector2.zero(),
);
// Flame은 기본적으로 nearest neighbor — 별도 설정 불필요
```

### 9.2 스케일 규칙 🔒
- **정수 배율만 허용** ❌ 분수 배율 금지 (2.5x, 1.75x 등)
- **허용 배율**: 1x, 2x, 3x, 4x
- **최소 지원 해상도**: 960×540 (= 스케일 2x)
- **권장 해상도**: 1920×1080 (= 스케일 4x)

### 9.3 반응형 대응 ⚙️
```dart
// 화면 크기에 따라 정수 배율 결정
final scale = (MediaQuery.sizeOf(context).width / 480).floor().clamp(1, 4);
Transform.scale(
  scale: scale.toDouble(),
  filterQuality: FilterQuality.none,
  child: Image.asset(AssetIds.charWizardIdle),
);
```

---

## §10. 총 에셋 수 카운터 & API 예산

### 10.1 최소 필요 에셋 수 (v1.0 기준)

| 섹션 | 에셋 수 |
|---|---|
| §5.1 타이틀·스플래시 | 5 |
| §5.2 중앙 홀 | 15 |
| §5.3 분관 내부 (10 × 4) | 40 |
| §5.4 대화 | 8 |
| §5.5 이론 뷰어 | 8 |
| §5.6 시뮬레이터 (4종) | 18 |
| §5.7 퀴즈 | 8 |
| §5.8 인벤토리 | 8 |
| §5.9 퀘스트 | 7 |
| §5.10 씬 전환 | 3 |
| **최소 합계** | **~120** |

### 10.2 PixelLab API 호출 수 추정

| 에셋 종류 | 필요 호출 수 |
|---|---|
| 정적 단일 프레임 | 1회 |
| 애니메이션 시트 (4프레임) | 2~3회 (create_character + animate_character) |
| Wang 타일셋 (16타일) | 1회 (create_tileset) |
| 9-slice 프레임 | 1회 |
| 스타일 앵커 3장 (최초) | 3회 |
| **예상 총 호출** | **180 ~ 220회** |

### 10.3 예산 확보 체크리스트
- [ ] PixelLab 구독 플랜 확인 — 월 200회 이상 지원?
- [ ] **재생성 버퍼 +30% 확보** (QA 실패 재생성 대비) → 실 예상 **260~290회**
- [ ] 개발 초기 앵커 3장에 생성 크레딧 충분히 투자 (앵커가 무너지면 나머지 전부 재작업)

---

## §11. 통합 체크리스트 (Bible + Manifest)

에셋 하나가 프로젝트에 편입되기 전, **두 문서 모두** 통과해야 한다.

### 11.1 Bible 체크 (스타일 기준)
- [ ] Bible §2 팔레트 외 색상 ≤ 2%
- [ ] Bible §2.2 색상 비율 준수
- [ ] Bible §3.2 표의 정확한 해상도
- [ ] Bible §5.2 공통 긍정 프롬프트 포함
- [ ] Bible §5.3 공통 네거티브 프롬프트 포함
- [ ] Bible §5.4 고정 파라미터 적용 (`text_guidance_scale=9.0` 등)
- [ ] Bible §7 QA 필수 항목 전부 통과

### 11.2 Manifest 체크 (아키텍처 기준)
- [ ] §1 레이어 책임 분리 (Flame/Flutter 중복 로드 없음)
- [ ] §3.2 스프라이트 시트 레이아웃 (가로 배열, 패딩 0, 크기 균일)
- [ ] §3.4 9-slice 코너 8×8 준수
- [ ] §4 애니메이션 상태 매트릭스의 필수 상태 포함
- [ ] §5 화면별 매니페스트에 등록됨
- [ ] §6 Asset ID 네이밍 규칙 준수
- [ ] §7 `pubspec.yaml` 에 해당 디렉토리 선언됨
- [ ] §9.1 `FilterQuality.none` 로드 보장

### 11.3 메타데이터 체크 (`.meta.json`)
- [ ] `bible_version` 필드 기록
- [ ] `manifest_version` 필드 기록
- [ ] `layer` 필드 기록 (`"flame"` / `"flutter"`)
- [ ] `animation_states` 배열 기록 (해당 시)

```json
{
  "asset_id": "char_wizard_idle_v1",
  "model": "bitforge",
  "style_anchor": "_anchors/anchor_character.png",
  "layer": "flame",
  "animation_states": ["idle", "talk"],
  "frame_count": 4,
  "frame_size": {"w": 64, "h": 96},
  "sheet_size": {"w": 256, "h": 96},
  "prompt": "...",
  "negative_prompt": "...",
  "params": { ... },
  "bible_version": "v1.0",
  "manifest_version": "v1.0",
  "qa_passed": true,
  "qa_reviewer": "reviewer_name",
  "qa_date": "2026-04-18"
}
```

---

## §12. 변경 로그

| 버전 | 날짜 | 변경 내역 |
|---|---|---|
| v1.0 | 2026-04-18 | 초기 매니페스트 확정. 분관 4개(Backend/Database/Frontend/Architecture) 확정. Architecture Wing 팔레트 규칙 명시. 총 에셋 수 ~120, API 호출 260~290회 추정. |

---

> *Bible이 에셋의 영혼을 정의한다면, Manifest는 에셋의 뼈대를 정의한다.*  
> *두 문서를 동시에 통과한 에셋만이 이 프로젝트에 존재할 자격을 얻는다.*
