# PixelLab AI 에셋 제작 기준 문서
## Asset Production Bible — Steampunk Arcane Library

> **버전**: v1.0  
> **최종 수정일**: 2026-04-18  
> **문서 목적**: 프로젝트 첫 번째 에셋과 N번째 에셋이 **같은 세계관, 같은 손에서** 나온 것처럼 보이도록 강제한다.

---

## 📌 이 문서를 쓰는 법

1. **§1 ~ §3** 는 **외워라.** (세계관 / 팔레트 / 스타일 헌법)
2. **§4** 의 스타일 앵커 3장을 **최초 1회** 제작한다. 이 3장이 프로젝트의 "그림 DNA" 다.
3. 모든 신규 에셋은 **§5 프롬프트 템플릿** + **§6 워크플로우** 로 생성한다.
4. 생성 후 반드시 **§7 QA 체크리스트** 를 통과시킨다. 실패 시 폐기·재생성.
5. 통과한 에셋은 **§8 네이밍 규칙** 으로 `.meta.json` 과 함께 저장한다.

### 표기 규약
- 🔒 **Locked** : 절대 변경 금지. 변경 시 이 문서 버전업 + 기존 에셋 전량 재검토.
- ⚙️ **Tunable** : 카테고리 단위로 조정 가능. 조정 시 §9 변경 로그에 기록.
- ❌ : 금지 사항. 발견 시 에셋 폐기.

---

## §1. 세계관 (Visual North Star)

### 1.1 컨셉 한 줄 🔒
> **"증기에 금빛 녹이 슨 고대 도서관, 보라색 마법광이 먼지처럼 떠다니는 곳."**

### 1.2 세 단어 🔒
`Steampunk` + `Arcane` + `Scholarly`  
(금지: `Cute`, `Neon`, `Sci-Fi`, `Cyberpunk`)

### 1.3 분관별 분위기 🔒

| 분관(기술 분야) | 지배색 | 메카닉·마법 모티프 | 조명 특성 |
|---|---|---|---|
| 메인 홀 | 갈색 + 금색 | 거대 톱니바퀴, 오르골, 샹들리에 | 따뜻한 황혼색 |
| Backend 관 | 갈색 + 구리 + 녹색 | 수증기 배관, 압력 밸브, 거대 기어 | 녹색 증기광 |
| Frontend 관 | 갈색 + 금색 + 시안 | 스테인드글라스, 프리즘, 거울 | 다색 프리즘광 |
| AI·마법 관 | 갈색 + 보라 | 룬 각인, 부유하는 책, 수정구 | 보라 마법광 |
| DB·기록 관 | 갈색 + 호박색 | 카탈로그 서랍, 카드, 인장 | 호박색 램프 |
| 인프라·지하 관 | 갈색 + 구리 + 오렌지 | 보일러, 용광로, 거대 체인 | 주황 화염광 |

**규칙**: 각 분관의 "지배색" 은 그 공간의 에셋에서 **전체 픽셀의 60% 이상** 점유해야 한다.

---

## §2. 팔레트 (The Locked Palette) 🔒

### 2.1 메인 팔레트 — 16색 고정

**이 팔레트 밖 색상 생성 금지.** 2% 이상 외부 색상 검출 시 에셋 폐기.

#### 기조색 (Base Browns) — 프로젝트의 40~60% 차지
| Hex | 이름 | 용도 |
|---|---|---|
| `#0f0b07` | Midnight Bark | 가장 어두운 그림자 (순흑 대체) |
| `#1a130c` | Old Oak | 일반 그림자 |
| `#2d2015` | Walnut | 중간톤 배경 |
| `#4a3620` | Amber Leather | 중간 밝기 |
| `#7a5a34` | Warm Brass | 밝은 갈색 하이라이트 |

#### 금속·악센트 (Metal & Accent) — 10~20% 차지
| Hex | 이름 | 용도 |
|---|---|---|
| `#b8860b` | Dark Goldenrod | 핵심 금색 (프로젝트 상징색) |
| `#d4a845` | Polished Gold | 금 하이라이트 |
| `#8b5e1a` | Tarnished Bronze | 구리·청동 기계 |

#### 마법광 (Arcane Purple) — AI·마법 관 지배색
| Hex | 이름 | 용도 |
|---|---|---|
| `#3a1a55` | Void Violet | 마법 그림자 |
| `#7b3ea8` | Arcane Purple | 중간 마법광 |
| `#b479e8` | Glowing Lilac | 마법 하이라이트 |

#### 증기·에너지 (Steam Green) — Backend 관 지배색
| Hex | 이름 | 용도 |
|---|---|---|
| `#1c3a2e` | Deep Moss | 증기 그림자 |
| `#3e7a5a` | Steam Verdigris | 일반 증기 |
| `#7de0a8` | Ectoplasm Green | 증기 하이라이트 |

#### 중립 (Neutral)
| Hex | 이름 | 용도 |
|---|---|---|
| `#e8dcc4` | Parchment | 종이·최고 하이라이트 (순백 대체) |

### 2.2 색상 비율 규칙 🔒

| 구분 | 허용 비율 |
|---|---|
| 갈색 기조 (5색 합) | **40 ~ 60%** |
| 금속·악센트 | **10 ~ 20%** |
| 마법광 **또는** 증기 (**양자택일**) | **5 ~ 15%** |
| Parchment | **≤ 5%** |
| 순흑(`#000000`) / 순백(`#FFFFFF`) | **0% — 사용 금지** ❌ |

> ⚠️ **양자택일 원칙**: 한 에셋에 보라 마법광 + 녹색 증기광을 **동시에 강하게** 쓰면 채도가 충돌해 탁해진다. 둘 중 하나를 메인(5~15%)으로, 나머지는 악센트(≤2%)로만 허용.

---

## §3. 아트 스타일 헌법

### 3.1 레퍼런스 🔒
- **1차**: *Celeste* — 절제된 팔레트, 선명한 대비, 명확한 실루엣
- **2차**: *Eastward* — 따뜻한 갈색조, 정교한 디테일, 부드러운 AA
- ❌ **금지 레퍼런스**: Stardew Valley(채도↑·귀여움↑), NES 8-bit(팔레트 부족), Terraria(너무 어지러움), Dead Cells(스케일 다름)

### 3.2 해상도 테이블 🔒

| 카테고리 | W × H (px) | 비율 | PixelLab 모델 |
|---|---|---|---|
| 캐릭터 (단일 프레임) | 64 × 96 | 2:3 | BitForge |
| 캐릭터 (4/8방향 세트) | 64 × 64 | 1:1 | `create_character` |
| 소품·오브젝트 (소) | 32 × 32 | 1:1 | BitForge |
| 소품·오브젝트 (대) | 64 × 64 | 1:1 | BitForge |
| 배경 타일 (Wang) | 32 × 32 | 1:1 | `create_tileset` |
| 배경 풀샷 | 256 × 144 | 16:9 | PixFlux |
| UI 아이콘 | 32 × 32 | 1:1 | BitForge |
| UI 프레임·패널 | 128 × 64 | 2:1 | BitForge |
| VFX 스프라이트 | 64 × 64 | 1:1 | BitForge |

> ❌ **위 표 외 해상도 금지.** "64×80 하나만 예외로" → 금지. 1픽셀도 예외 없음.

### 3.3 아웃라인 🔒
- `outline="selective outline"` **항상**
- 외곽선 색: 검정이 아니라 **해당 영역의 가장 어두운 톤**
  - 예: 갈색 조끼 → `#0f0b07` 외곽선 / 금색 버클 → `#4a3620` 외곽선
- 내부 세부선: **사용 금지.** 셰이딩으로만 표현.

### 3.4 셰이딩 🔒
- `shading="basic shading"`
- **광원 방향**: **항상 좌상단 (10시 방향)** — 그림자는 우하단에 떨어져야 한다.
- **그림자 단계**: 3단계 (하이라이트 / 기본 / 그림자) — 4단계 이상 금지.
- **안티에일리어싱**: 허용 (Eastward 풍). 단, 캐릭터 **실루엣 외곽**에는 사용 금지 (실루엣은 선명해야 함).

### 3.5 디테일 레벨 ⚙️
| 카테고리 | detail 파라미터 |
|---|---|
| 캐릭터 (특히 얼굴·악세서리) | `"highly detailed"` |
| 소품·UI 아이콘 | `"medium detail"` (기본) |
| 배경 타일 (반복용) | `"low detail"` *(반복 시 노이즈 방지)* |
| 배경 풀샷 | `"medium detail"` |
| VFX | `"medium detail"` |

### 3.6 카메라·투영 🔒
- **2D 평면** 기준 (탑다운·사이드뷰 혼용)
- 캐릭터: 정면 또는 3/4 뷰
- ❌ **아이소메트릭 금지** (이 프로젝트는 2D 평면)
- 원근감: **최소화** (타일 기반이므로 평면감 유지)

---

## §4. 스타일 앵커 프로토콜 (Style Anchor Protocol)

### 4.1 왜 앵커가 필요한가?
BitForge 모델의 `style_image` 한 장은 결과물 스타일의 **70% 이상을 결정한다.** 
모든 이후 에셋이 이 앵커를 참조해야 "같은 손" 이 유지된다. 앵커 없이 PixFlux만 반복 사용하면 5번째 에셋부터 스타일이 흔들린다.

### 4.2 앵커 3종 세트 (최초 1회 제작)

| 앵커명 | 용도 | 해상도 | 포함해야 할 요소 |
|---|---|---|---|
| `anchor_character.png` | 모든 캐릭터 생성 기준 | 64 × 96 | 사서 NPC 1명 — 안경, 조끼, 책, 보라색 마법 발광 |
| `anchor_environment.png` | 배경·타일 기준 | 256 × 144 | 책장 복도, 증기 배관, 금색 램프, 멀리 보이는 기어 |
| `anchor_object.png` | 소품·UI·VFX 기준 | 64 × 64 | 놋쇠 주전자 + 룬 각인 책 세트 |

### 4.3 앵커 생성 명령 예시 (PixFlux)

```python
generate_image_pixflux(
  description=(
    "elderly librarian character, dark brown leather vest, brass goggles, "
    "holding a leather-bound tome with glowing purple runes, "
    "standing in steampunk arcane library, green steam drifting in background, "
    "Celeste and Eastward pixel art style, "
    "dark brown and gold color palette with purple magic accent, "
    "warm amber lighting from top-left, selective outline"
  ),
  width=64,
  height=96,
  negative_description=(
    "bright neon colors, saturated, pure white, pure black outlines, "
    "anime, chibi, 8-bit NES retro, Stardew Valley cute style, "
    "photorealistic, 3D render, blurry, modern technology, sci-fi laser"
  ),
  text_guidance_scale=10.0,
  no_background=True,
  outline="selective outline",
  shading="basic shading",
  detail="highly detailed"
)
```

### 4.4 앵커 승인 게이트 (3장 모두 통과해야 본 작업 시작)

- [ ] §2.1 팔레트 외 색상 비율 ≤ 2%
- [ ] §2.2 비율 규칙 준수 (갈색 기조 40~60%)
- [ ] 광원이 좌상단에서 내려옴 (그림자 우하단 확인)
- [ ] 외곽선이 순흑이 아닌 **어두운 갈색** (`#0f0b07` 계열)
- [ ] Celeste 와 Eastward 사이 "어딘가의" 분위기
- [ ] 리뷰어 2명 이상이 "같은 세계관" 이라고 동의

> ❗ 앵커 승인 이후 **앵커 수정 = 프로젝트 전체 에셋 재검토**. 신중히.

---

## §5. 프롬프트 작성 규칙

### 5.1 프롬프트 골격 🔒 (항상 이 순서)

```
[SUBJECT], [POSE/ACTION], [KEY DETAILS],
in steampunk arcane library setting,
Celeste and Eastward pixel art style,
dark brown and gold color palette with [SECONDARY] accent,
warm lighting from top-left, selective outline, [DETAIL_LEVEL]
```

- `[SECONDARY]` 는 다음 중 **하나만** 고른다: `purple magic` | `green steam` | `amber warm` | `cyan prism`
- `[DETAIL_LEVEL]` : `highly detailed` | `medium detail` | `low detail` (§3.5 표 따라)

### 5.2 공통 긍정 프롬프트 🔒 (모든 description 끝에 **반드시** 추가)

```
, Celeste and Eastward pixel art style,
  dark brown and gold color palette,
  warm top-left lighting, selective outline
```

### 5.3 공통 네거티브 프롬프트 🔒 (모든 negative_description 에 **반드시** 포함)

```
bright neon colors, saturated, vibrant, pure white, pure black outlines,
anime, chibi, manga, kawaii, 8-bit NES retro, Stardew Valley cute style,
photorealistic, 3D render, blurry, low resolution,
modern technology, sci-fi laser, cyberpunk, Christmas colors, rainbow
```

### 5.4 고정 파라미터 🔒

| 파라미터 | 값 | 변경 가능? |
|---|---|---|
| `text_guidance_scale` | **`9.0`** | ❌ (QA 실패 시 한정적으로 8~11 조정) |
| `outline` | `"selective outline"` | ❌ |
| `shading` | `"basic shading"` | ❌ |
| `detail` | §3.5 표 참조 | ⚙️ 카테고리 한정 |
| `no_background` | 캐릭터·오브젝트·UI·VFX: `True` / 배경 풀샷·타일: `False` | ⚙️ |

### 5.5 카테고리별 프롬프트 예시

**[캐릭터] — BitForge + `anchor_character.png`**
```
young mechanic apprentice, standing idle facing right,
brass tool belt and ink-stained apron, holding a glowing green steam wrench,
Celeste and Eastward pixel art style,
dark brown and gold color palette with green steam accent,
warm lighting from top-left, selective outline, highly detailed
```

**[배경 타일] — create_tileset + 앵커 참조**
```
lower: "worn dark brown wooden library floor with brass inlay, low detail",
upper: "ornate brass grating with green steam vents, low detail"
```

**[오브젝트] — BitForge + `anchor_object.png`**
```
ancient tome, leather-bound with brass clasps, glowing purple runes on cover,
single item on transparent background,
Celeste and Eastward pixel art style,
dark brown and gold color palette with purple magic accent,
warm lighting from top-left, selective outline, highly detailed
```

**[UI 아이콘] — BitForge + `anchor_object.png`**
```
inventory slot icon showing a brass key with tiny gear teeth,
single item centered, transparent background,
Celeste and Eastward pixel art style,
dark brown and gold color palette,
warm lighting from top-left, selective outline, medium detail
```

**[VFX] — BitForge + `anchor_object.png`**
```
swirling purple magical smoke effect, single frame,
centered on transparent background,
Celeste and Eastward pixel art style,
purple magic palette (void violet, arcane purple, glowing lilac),
selective outline, medium detail
```

---

## §6. 생성 워크플로우

### 6.1 의사결정 트리

```
신규 에셋 요청
    ↓
① §3.2 해상도 테이블에서 카테고리 매칭 → 크기·모델 확정
    ↓
② 모델 선택
   ├─ 배경 풀샷 단일 씬 → PixFlux (앵커 참조 불가, 보정 필요)
   ├─ 캐릭터 4/8방향    → create_character + 앵커 키워드 일관 적용
   ├─ Wang 타일셋       → create_tileset
   └─ 그 외 (대부분)    → BitForge + style_image=앵커
    ↓
③ §5.1 골격 + §5.2 공통긍정 + §5.3 공통네거티브 조립
    ↓
④ §5.4 고정 파라미터 적용하여 생성
    ↓
⑤ §7 QA 체크리스트 실행
    ↓
   Pass → §8 네이밍 규칙으로 저장 (meta.json 포함)
   Fail → §7.3 대응 표로 프롬프트 조정 후 ④로
```

### 6.2 카테고리별 요약 표

| 카테고리 | 해상도 | 모델 | 스타일 앵커 | no_background |
|---|---|---|---|---|
| 캐릭터 단일 | 64×96 | BitForge | `anchor_character.png` | True |
| 캐릭터 방향 세트 | 64×64 | `create_character` | (앵커 키워드 일관) | True |
| 소품 소/대 | 32·64 | BitForge | `anchor_object.png` | True |
| 배경 풀샷 | 256×144 | PixFlux | ❌ 불가 → 생성 후 BitForge 재보정 | False |
| 바닥·벽 타일 | 32×32 | `create_tileset` | (키워드 일관) | N/A |
| UI 아이콘 | 32×32 | BitForge | `anchor_object.png` | True |
| UI 프레임 | 128×64 | BitForge | `anchor_object.png` | True |
| VFX | 64×64 | BitForge | `anchor_object.png` | True |

> ⚠️ **PixFlux 의 한계**: 스타일 이미지를 참조할 수 없다. 배경 풀샷 생성 후에는 반드시 BitForge 로 **inpainting 또는 부분 재생성**을 거쳐 톤을 앵커에 맞춰야 한다.

---

## §7. QA 체크리스트 (Asset Gate)

### 7.1 필수 통과 (Pass / Fail) — 하나라도 실패 시 **폐기**

- [ ] **팔레트**: §2.1 16색 외 색상이 전체 픽셀의 **2% 이하**
- [ ] **비율**: §2.2 기조색 40~60% / 금속 10~20% / 악센트 5~15%
- [ ] **순흑·순백 금지**: `#000000`, `#FFFFFF` 사용률 **0%**
- [ ] **해상도**: §3.2 표와 **정확히 일치** (64×80 같은 예외 금지)
- [ ] **광원 방향**: 좌상단 → 우하단 그림자 (반대면 폐기)
- [ ] **배경 처리**: 캐릭터·오브젝트·UI·VFX 는 투명 배경 (alpha=0)
- [ ] **금지 스타일 미등장**: 네온, 3D, 애니·치비, 네스 8비트 느낌 없음
- [ ] **양자택일**: 보라 마법광 + 녹색 증기광 동시 강조 없음

### 7.2 품질 체크 (Quality) — **3개 이상** 통과 권장

- [ ] 앵커 에셋과 나란히 놓아도 같은 "손" 에서 나온 느낌
- [ ] 디테일이 §3.5 레벨과 일치 (과도·과소 없음)
- [ ] 실루엣만 봐도 무엇인지 식별 가능
- [ ] 같은 카테고리의 기존 에셋과 크기·톤 일치
- [ ] 분관 지배색 규칙 (60%+) 준수

### 7.3 QA 실패 시 대응 매트릭스

| 증상 | 원인 추정 | 조치 |
|---|---|---|
| 색이 너무 밝음·채도 높음 | `text_guidance_scale` 부족 | 9.0 → 11.0 상향, 네거티브에 `saturated, vibrant` 보강 |
| 애니·치비 스타일 섞임 | description 단어 선택 문제 | `character` → `person in pixel art`, 네거티브에 `anime, manga, chibi` 보강 |
| 디테일 과잉 | detail 파라미터 | `"medium detail"` 고정 + 네거티브 `cluttered, busy` |
| 금색이 노랑처럼 보임 | 팔레트 키워드 약함 | description 에 `dark brass, tarnished gold, not yellow` 명시 |
| 앵커와 톤 다름 | `style_image` 미전달 | BitForge 재생성, 앵커 경로 재확인 |
| 순흑 아웃라인 | `selective outline` 무효화 | 프롬프트에 `no pure black outline, use dark brown outline` 추가 |
| 광원 반대 | 프롬프트 방향 부재 | `warm lighting from top-left, shadows on bottom-right` 강화 |
| 배경 남음 | `no_background=False` | 파라미터 확인, 또는 후처리 제거 |

---

## §8. 네이밍 · 파일 관리

### 8.1 디렉토리 구조 🔒

```
assets/
├── _anchors/                          ← 절대 수정 금지
│   ├── anchor_character.png
│   ├── anchor_environment.png
│   └── anchor_object.png
├── characters/
│   └── {캐릭터_ID}/
│       ├── {ID}_idle.png
│       ├── {ID}_walk_n.png
│       ├── {ID}_walk_e.png
│       └── {ID}.meta.json
├── environments/
│   ├── main_hall/
│   ├── backend_wing/
│   ├── frontend_wing/
│   ├── ai_magic_wing/
│   └── db_archive_wing/
├── objects/
├── ui/
│   ├── icons/
│   └── frames/
└── vfx/
```

### 8.2 파일명 규칙 🔒

```
{카테고리약어}_{서브카테고리}_{이름}_{상태}_{방향}_v{버전}.png
```

| 카테고리 | 약어 |
|---|---|
| 캐릭터 | `char` |
| 환경 | `env` |
| 오브젝트 | `obj` |
| UI | `ui` |
| VFX | `vfx` |

**예시**:
- `char_npc_mechanic_walk_e_v1.png`
- `env_backend_floor_tile_01_v1.png`
- `obj_book_arcane_v2.png`
- `ui_icon_inventory_key_v1.png`
- `vfx_magic_smoke_purple_f3_v1.png`

### 8.3 `.meta.json` 필수 필드

**모든 에셋은 동일 이름의 `.meta.json` 을 반드시 동반한다.** (재현성 확보)

```json
{
  "asset_id": "char_npc_mechanic_idle_v1",
  "model": "bitforge",
  "style_anchor": "_anchors/anchor_character.png",
  "prompt": "young mechanic apprentice, standing idle facing right, ...",
  "negative_prompt": "bright neon colors, saturated, ...",
  "params": {
    "width": 64,
    "height": 96,
    "text_guidance_scale": 9.0,
    "outline": "selective outline",
    "shading": "basic shading",
    "detail": "highly detailed",
    "no_background": true
  },
  "bible_version": "v1.0",
  "qa_passed": true,
  "qa_reviewer": "reviewer_name",
  "qa_date": "2026-04-18",
  "notes": ""
}
```

> ❗ `.meta.json` 이 없는 에셋은 **재생성이 불가능**하다. 본 문서의 기준이 바뀌면 일괄 재생성이 필요한데, 프롬프트 기록이 없으면 손수 재작성해야 한다.

---

## §9. 변경 관리 (Change Control)

### 9.1 🔒 Locked 항목 변경 절차
§1~§5 의 🔒 표시 항목을 변경하려면:

1. 변경 제안 이슈 생성 (변경 사유 + 영향 범위 + 예상 영향 에셋 수)
2. 리뷰어 2명 이상 승인
3. **본 문서의 Major 버전 업** (v1.0 → v2.0)
4. 기존 에셋 **전량 재검토** → 재생성 여부 결정

### 9.2 ⚙️ Tunable 항목 변경
카테고리 단위 조정 가능. 변경 시 **§9.3 로그**에 기록. Minor 버전 업 (v1.0 → v1.1).

### 9.3 변경 로그

| 버전 | 날짜 | 변경 내역 | 작성자 |
|---|---|---|---|
| v1.0 | 2026-04-18 | 초기 기준 문서 확정 | — |

---

## §10. 생성 직전 5줄 체크 (Pre-flight Checklist)

에셋 하나를 생성하기 직전, 스스로에게 묻는다:

1. ✅ §3.2 표의 **정확한 해상도**인가?
2. ✅ §5.2 공통 긍정 + §5.3 공통 네거티브가 **모두 포함**됐는가?
3. ✅ §5.4 **고정 파라미터**가 적용됐는가?  (`text_guidance_scale=9.0`, `outline="selective outline"`, `shading="basic shading"`)
4. ✅ 카테고리에 맞는 **스타일 앵커**가 `style_image_path` 에 들어갔는가? (PixFlux 제외)
5. ✅ 생성 후 §7 **QA 체크리스트**를 실행할 준비가 됐는가?

**5개 모두 YES → 생성 진행. 하나라도 NO → 멈춤.**

---

## 부록 A. 팔레트 빠른 복사용

```
기조색: #0f0b07 #1a130c #2d2015 #4a3620 #7a5a34
금속:   #b8860b #d4a845 #8b5e1a
마법:   #3a1a55 #7b3ea8 #b479e8
증기:   #1c3a2e #3e7a5a #7de0a8
중립:   #e8dcc4
```

## 부록 B. 프롬프트 빠른 복사용

**공통 긍정 (항상 description 끝에)**
```
, Celeste and Eastward pixel art style, dark brown and gold color palette, warm top-left lighting, selective outline
```

**공통 네거티브 (항상 negative_description 에)**
```
bright neon colors, saturated, vibrant, pure white, pure black outlines, anime, chibi, manga, kawaii, 8-bit NES retro, Stardew Valley cute style, photorealistic, 3D render, blurry, low resolution, modern technology, sci-fi laser, cyberpunk, Christmas colors, rainbow
```

**고정 파라미터 JSON**
```json
{
  "text_guidance_scale": 9.0,
  "outline": "selective outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "no_background": true
}
```

---

> *이 문서는 프로젝트가 끝날 때까지 살아 있다.  
> 모든 에셋이 이 기준을 통과하는 한, 1번 에셋과 마지막 에셋은 같은 세계관에 존재한다.*
