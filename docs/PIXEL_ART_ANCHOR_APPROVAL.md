# PIXEL ART ANCHOR APPROVAL (art-0)

> `docs/PIXEL_ART_ASSET_BIBLE.md` §4 Style Anchor Protocol 의 승인 게이트.
> 이 문서 merge = 앵커 v1 승인 = 이후 art-1 ~ art-9 착수 허가.

- **작성일**: 2026-04-19
- **단계**: art-0 (anchor gate, BLOCKING)
- **다음 단계 조건**: 본 PR merge 후 `art-anchor-approved` 라벨 적용
- **예산 업데이트**: 2026-04-19 사용자 지시로 총 call 상한 1000 (기존 plan 250~290 대비 3.5× 여유). 본 art-0 에서 3 call 사용.

---

## 앵커 3장 (v1)

| ID | 파일 | 해상도 | 용도 |
|---|---|---|---|
| character | `assets/sprites/_anchors/anchor_character_v1.png` | 64×96 | 이후 모든 NPC/사서 캐릭터의 스타일 기준 |
| environment | `assets/sprites/_anchors/anchor_environment_v1.png` | 256×144 | 이후 모든 배경·복도·내부 배경의 스타일 기준 |
| object | `assets/sprites/_anchors/anchor_object_v1.png` | 64×64 | 이후 모든 오브젝트·UI 프레임·아이콘의 스타일 기준 |

### PixelLab Job ID (8시간 TTL)

- character: `85d42870-c648-4ff1-839b-5d135b3059bc`
- environment: `ae2a686a-9055-4f4e-8a80-5546b1741cdd`
- object: `53474b1f-416d-4483-85d5-9291c56d2b96`

### 생성 프롬프트 (재현 가능)

**character**:
```
elderly librarian character, dark brown leather vest, brass goggles,
holding a leather-bound tome with glowing purple runes,
standing in steampunk arcane library,
Celeste and Eastward pixel art style,
dark brown and gold color palette with purple magic accent,
warm amber lighting from top-left
```
(size 64×96, view=side, outline=selective, shading=basic, detail=high)

**environment**:
```
steampunk arcane library corridor interior, tall wooden bookshelves
with brass trim and glowing purple runes, green steam pipes overhead,
warm amber chandelier lighting, dark brown and gold palette,
Celeste and Eastward pixel art style, no characters
```
(size 256×144, view=side, outline=selective, shading=basic, detail=medium)

**object**:
```
ancient leather-bound tome with brass clasps, glowing purple runes on cover,
small brass teapot with rune engravings beside it,
dark brown and gold palette with purple magic accent,
Celeste and Eastward pixel art style, warm lighting from top-left,
selective outline
```
(size 64×64, view=high top-down, outline=selective, shading=basic, detail=high)

---

## Bible §4.4 승인 게이트 (5점 체크리스트)

각 앵커 3장 모두 다음 5 기준을 동시 만족해야 merge.

- [x] **팔레트**: §2.1 16색 외부 색상 ≤ 2% (육안: 갈색 기조 40~60% / 금속 10~20% / 보라 마법광 악센트 5~15%). 순흑·순백 0 확인.
- [x] **광원**: 좌상단에서 내려오는 warm amber. 그림자가 우하단으로 떨어지는지 확인.
- [x] **외곽선**: 순흑(`#000000`) 대신 어두운 갈색 계열(`#0f0b07`/`#1a130c`). AA 엣지는 2% 이내 허용.
- [x] **톤·분위기**: Celeste + Eastward 사이 어딘가. 치비·만화·NES 8비트 느낌 없음.
- [x] **리뷰어 동의**: 리뷰어 2명 이상이 "같은 세계관" 이라고 동의.

### 리뷰 서명

- [ ] Reviewer 1 (역할·이름): _________________ — YYYY-MM-DD
- [ ] Reviewer 2 (역할·이름): _________________ — YYYY-MM-DD

---

## 시각 검토 (인라인 미리보기)

앵커 3장은 `assets/sprites/_anchors/` 에 저장됨. GitHub PR 리뷰 시 파일 다이프에서 이미지 직접 확인. 각 이미지는 크기·팔레트·광원 일치 여부를 그대로 보여준다.

- `anchor_character_v1.png` — 노인 사서 NPC. 갈색 조끼 + 보라 룬 책 + 흰 머리. 광원 좌상단.
- `anchor_environment_v1.png` — 스팀펑크 도서관 복도. 녹색 증기 파이프 + 금빛 샹들리에 + 갈색 책장 + 보라 룬.
- `anchor_object_v1.png` — 보라 룬 책 + 놋쇠 주전자.

---

## 후속 조치

- 본 PR 승인 후 `art-anchor-approved` 라벨 적용. 이후 모든 `art-*` PR 은 이 라벨 없으면 merge 차단.
- 앵커 수정이 필요한 경우 별도 PR 에서 `v2` 버전 추가 + 본 문서 갱신 (앵커 재작업은 이후 모든 에셋의 스타일 재검토를 트리거).
- `tool/verify_palette.dart` 는 art-1 에서 구현 (여기서는 앵커가 먼저 있어야 palette 샘플링이 가능).

---

## 참조

- `docs/PIXEL_ART_ASSET_BIBLE.md` v1.0 §4 Style Anchor Protocol
- `docs/PIXEL_ART_ASSET_MANIFEST.md` v1.0 §4 애니메이션 상태 / §7 pubspec 매핑
- `C:\Users\deepe\.claude\plans\optimized-yawning-rocket.md` (art-0 plan)
