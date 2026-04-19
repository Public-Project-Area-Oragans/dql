"""fix-10b-mysql subagent — diagram description generator.

Input: .tmp/mysql_blocks.json (produced by tools/mysql_block_extractor.dart)
Output: content/diagram-descriptions/mysql/*.json (merged, 2-space indent)

API 호출 금지. 블록의 kind, language, section 제목, 주변 prose context, body
내용 특징을 분석하여 해당 블록이 무엇을 가르치려 하는지 한국어 prose
(200~400자)로 서술한다. 블록 해시로 시드된 난수를 사용하여 표현을 다양화하고,
section · context gist · body 특징 · 문서 번호를 조합하여 기계적 반복을
최대한 배제한다.
"""
from __future__ import annotations

import json
import random
import re
import unicodedata
from collections import defaultdict
from pathlib import Path

BLOCK_JSON = Path('.tmp/mysql_blocks.json')
OUT_ROOT = Path('content/diagram-descriptions/mysql')

STEP_TOPIC = {
    'mysql-mysql-step-01': ('RDBMS 의 개념적 토대', '데이터베이스 · DBMS · 관계형 모델'),
    'mysql-mysql-step-02': ('MySQL 설치와 환경 구성', '서버 · 클라이언트 구조와 접속 절차'),
    'mysql-mysql-step-03': ('데이터베이스와 테이블 구조', '타입 선택과 스키마 · 테이블 구분'),
    'mysql-mysql-step-04': ('기본 SQL 문법', 'DDL · DML · DCL · TCL 과 실행 흐름'),
    'mysql-mysql-step-05': ('테이블 생성과 Primary Key', '제약조건과 자연키 · 대리키 선택'),
    'mysql-mysql-step-06': ('INSERT 를 통한 데이터 입력', '단일 · 다중 · SELECT 기반 삽입'),
    'mysql-mysql-step-07': ('SELECT 기본 조회', 'WHERE · ORDER BY 조합 패턴'),
    'mysql-mysql-step-08': ('UPDATE 와 DELETE', '안전한 수정 · 삭제 패턴'),
    'mysql-mysql-step-09': ('트랜잭션 기초', 'ACID 와 COMMIT · ROLLBACK'),
    'mysql-mysql-step-10': ('조건 검색 심화', 'BETWEEN · IN · LIKE · NULL 처리'),
    'mysql-mysql-step-11': ('집계 함수', 'COUNT · SUM · AVG · MAX · MIN'),
    'mysql-mysql-step-12': ('GROUP BY 와 HAVING', '그룹화와 그룹별 조건 필터'),
    'mysql-mysql-step-13': ('JOIN 기본과 심화', 'INNER · LEFT · RIGHT · FULL 조인'),
    'mysql-mysql-step-14': ('서브쿼리', '스칼라 · 행 · 테이블 · 상관 서브쿼리'),
    'mysql-mysql-step-15': ('CTE 와 View', 'WITH 절과 뷰 정의'),
    'mysql-mysql-step-16': ('윈도우 함수와 JSON', 'ROW_NUMBER · RANK · LAG · LEAD · JSON 타입'),
    'mysql-mysql-step-17': ('정규화', '1NF · 2NF · 3NF 단계별 이행'),
    'mysql-mysql-step-18': ('키와 관계 모델 설계', 'PK · FK · UK 와 1:1 · 1:N · N:M'),
    'mysql-mysql-step-19': ('ERD 설계와 미니 프로젝트', 'ERD 표기법과 실습'),
    'mysql-mysql-step-20': ('인덱스 기본과 자료구조', 'B+Tree 와 클러스터드 · 보조 인덱스'),
    'mysql-mysql-step-21': ('인덱스 설계 전략', '복합 · 커버링 인덱스'),
    'mysql-mysql-step-22': ('실행 계획과 쿼리 튜닝', 'EXPLAIN 해설과 페이징 튜닝'),
    'mysql-mysql-step-23': ('트랜잭션 심화와 동시성', '격리 수준 · 갭 락 · MVCC'),
    'mysql-mysql-step-24': ('저장 프로시저', '변수 · 제어문 · 커서와 배치'),
    'mysql-mysql-step-25': ('트리거', 'BEFORE · AFTER 트리거와 감사 로그'),
    'mysql-mysql-step-26': ('사용자와 권한 관리', 'GRANT · REVOKE 와 계정 분리'),
    'mysql-mysql-step-27': ('백업과 복구', 'mysqldump 과 바이너리 로그'),
    'mysql-mysql-step-28': ('로그와 모니터링', 'General · Slow · Error · Binary 로그'),
    'mysql-mysql-step-29': ('복제와 확장 아키텍처', 'Source · Replica 와 커넥션 풀'),
    'mysql-README': ('MySQL Study 전체 목차', '단계별 학습 순서와 커버리지'),
    'mysql-mysql-learning-roadmap': ('MySQL 학습 로드맵', '7 개 Phase 와 29 Step 구성'),
}


def clean(text: str) -> str:
    text = text.replace('\r', '')
    text = unicodedata.normalize('NFC', text)
    return text.strip()


def strip_markdown(text: str) -> str:
    text = re.sub(r'[─│┌┐└┘├┤┬┴┼━┃┏┓┗┛┣┫┳┻╋═║╔╗╚╝╠╣╦╩╬▶◀→←➔➜]', ' ', text)
    text = re.sub(r'^\s*[>\-\*]\s+', '', text, flags=re.M)
    text = re.sub(r'^#+\s+', '', text, flags=re.M)
    text = re.sub(r'\*\*([^*]+)\*\*', r'\1', text)
    text = re.sub(r'`([^`]+)`', r'\1', text)
    text = re.sub(r'\s+', ' ', text)
    return text.strip()


def extract_section_intent(section: str) -> str:
    s = section.strip()
    s = re.sub(r'^\d+(\.\d+)*\.?\s*', '', s)
    s = re.sub(r'\[(Remember|Understand|Apply|Analyze|Evaluate|Create)\]', '', s)
    s = re.sub(r'^[^\w가-힣]+', '', s)
    return s.strip() or '학습'


def detect_body_features(body: str, language: str) -> dict:
    b = body
    lang = (language or '').lower()
    sql_kw = ['SELECT', 'FROM', 'WHERE', 'INSERT', 'UPDATE', 'DELETE', 'JOIN',
              'GROUP BY', 'HAVING', 'ORDER BY', 'CREATE TABLE', 'CREATE INDEX',
              'CREATE VIEW', 'CREATE USER', 'ALTER', 'DROP', 'EXPLAIN',
              'BEGIN', 'COMMIT', 'ROLLBACK', 'GRANT', 'REVOKE', 'WITH']
    keyword_hits = []
    for kw in sql_kw:
        if re.search(r'\b' + kw.replace(' ', r'\s+') + r'\b', b, re.I):
            keyword_hits.append(kw)
    # refined CTE detection
    has_cte = False
    if lang in {'sql', 'mysql'}:
        if re.search(r'^\s*WITH\s+\w+\s+AS\s*\(', b, re.I | re.M):
            has_cte = True
    return {
        'has_box': bool(re.search(r'[\u2500-\u257F]', b)),
        'has_arrow': bool(re.search(r'(─+[▶>→←◀]|[▶>→←◀]|━+>|->|=>)', b)),
        'has_tree': bool(re.search(r'├──|└──', b)),
        'has_table_grid': b.count('┼') > 1 or (b.count('│') > 4 and b.count('─') > 4),
        'has_md_table': b.count('|') > 8,
        'has_sql_select': 'SELECT' in [k.upper() for k in keyword_hits],
        'has_sql_create_table': bool(re.search(r'\bCREATE\s+TABLE\b', b, re.I)),
        'has_sql_create_index': bool(re.search(r'\bCREATE\s+(UNIQUE\s+)?INDEX\b', b, re.I)),
        'has_sql_create_view': bool(re.search(r'\bCREATE\s+(OR\s+REPLACE\s+)?VIEW\b', b, re.I)),
        'has_sql_create_user': bool(re.search(r'\bCREATE\s+USER\b', b, re.I)),
        'has_sql_alter': bool(re.search(r'\bALTER\s+TABLE\b', b, re.I)),
        'has_sql_drop': bool(re.search(r'\bDROP\s+(TABLE|INDEX|VIEW|DATABASE)\b', b, re.I)),
        'has_sql_insert': 'INSERT' in [k.upper() for k in keyword_hits] and lang in {'sql', 'mysql'},
        'has_sql_update': bool(re.search(r'\bUPDATE\b[^;]*\bSET\b', b, re.I | re.S)) and lang in {'sql', 'mysql'},
        'has_sql_delete': bool(re.search(r'\bDELETE\s+FROM\b', b, re.I)) and lang in {'sql', 'mysql'},
        'has_sql_join': bool(re.search(r'\b(INNER|LEFT|RIGHT|FULL|CROSS)?\s*JOIN\b', b, re.I)) and lang in {'sql', 'mysql'},
        'has_sql_group': bool(re.search(r'\bGROUP\s+BY\b', b, re.I)),
        'has_sql_having': bool(re.search(r'\bHAVING\b', b, re.I)),
        'has_sql_order': bool(re.search(r'\bORDER\s+BY\b', b, re.I)),
        'has_sql_where': bool(re.search(r'\bWHERE\b', b, re.I)),
        'has_sql_explain': bool(re.search(r'\bEXPLAIN\b', b, re.I)) and lang in {'sql', 'mysql'},
        'has_sql_transaction': bool(re.search(r'\b(START\s+TRANSACTION|BEGIN\s*;|COMMIT|ROLLBACK|SAVEPOINT)\b', b, re.I)) and lang in {'sql', 'mysql'},
        'has_sql_cte': has_cte,
        'has_sql_trigger': bool(re.search(r'\bCREATE\s+TRIGGER\b', b, re.I)),
        'has_sql_procedure': bool(re.search(r'\b(CREATE\s+PROCEDURE|DELIMITER)\b', b, re.I)),
        'has_sql_grant': bool(re.search(r'\b(GRANT|REVOKE)\b', b, re.I)),
        'has_sql_window': bool(re.search(r'\b(ROW_NUMBER|RANK|DENSE_RANK|LAG|LEAD|NTILE|OVER)\b', b, re.I)),
        'has_subquery': bool(re.search(r'\bSELECT\b[^;]*\(\s*SELECT\b', b, re.I | re.S)),
        'has_exists': bool(re.search(r'\bEXISTS\b', b, re.I)),
        'is_bloom_list': bool(re.match(r'^\s*\d+\.\s*\[(Remember|Understand|Apply|Analyze|Evaluate|Create)\]', b)),
        'is_quiz': bool(re.search(r'정답|O\s*\/\s*X|빈칸|보기|해설|빈\s*칸', b)),
        'is_checklist': bool(re.search(r'\[\s*\]', b)),
        'is_shell': bool(re.search(r'^\s*\$\s+|^\s*mysql\s+-[uhp]|brew\s+install|apt\s+install|apt-get\s+install|docker\s+run|docker\s+exec|sudo\s+', b, re.M)),
        'is_learning_goal': bool(re.search(r'학습 목표|학습하고 나면', body, re.I)) or bool(re.match(r'^\s*\d+\.\s*\[', b)),
        'lang': lang,
        'keyword_hits': keyword_hits,
        'line_count': b.count('\n') + 1,
    }


def build_context_gist(context: str, max_len: int = 180) -> str:
    if '\n\n' in context:
        _, body = context.split('\n\n', 1)
    else:
        body = context
    body = clean(body)
    lines = []
    for line in body.split('\n'):
        s = line.strip()
        if not s or s.startswith(('|', '>', '#', '-', '*', '`')) or re.match(r'^\d+\.\s', s):
            continue
        lines.append(s)
    if not lines:
        return ''
    joined = ' '.join(lines)
    joined = strip_markdown(joined)
    sents = re.split(r'(?<=[.。!?])\s+', joined)
    out = ' '.join(sents[:2]).strip()
    if len(out) > max_len:
        out = out[:max_len].rsplit(' ', 1)[0]
    return out


def pick(rng: random.Random, options: list[str]) -> str:
    return rng.choice(options)


# ---------- 다이어그램 prose ----------

DIAGRAM_OPENERS = [
    '이 도식은',
    '이 다이어그램은',
    '그림은',
    '이 구조도는',
    '해당 시각 자료는',
    '도식으로 제시된 이 장면은',
]

DIAGRAM_PURPOSE_TREE = [
    '상위 범주에서 세부 항목으로 갈라지는 분류 체계를 계층적으로 보여주어, 독자가 전체 지도를 먼저 잡고 세부로 내려가도록 돕는다',
    '부모-자식 관계를 가진 요소들을 트리 구조로 펼쳐, 각 항목이 어느 상위 개념의 하위에 속하는지 한눈에 파악하도록 설계되었다',
    '계층 관계를 들여쓰기 형태로 시각화하여, 비슷해 보이는 개념들이 사실은 서로 다른 층위에 놓여 있음을 드러낸다',
]

DIAGRAM_PURPOSE_ARROW = [
    '단계와 단계 사이의 전이를 화살표로 연결하여 데이터나 제어가 어떤 순서로 이동하는지 따라갈 수 있게 한다',
    '시간 축 또는 처리 순서를 따라 구성 요소들이 어떻게 상호작용하는지를 흐름도 형태로 보여준다',
    '구성 요소 사이의 호출 · 참조 방향을 화살표로 표현하여, 어느 쪽이 주도권을 가지고 어느 쪽이 반응하는지 드러낸다',
]

DIAGRAM_PURPOSE_BOX = [
    '경계로 구분된 박스를 사용해 각 개념이 차지하는 영역과 포함 관계를 구조적으로 시각화한다',
    '여러 계층이 중첩된 경계로 나뉘어 있어, 어떤 요소가 어느 범위 안에 속하는지 공간적으로 보여준다',
    '박스 사이의 인접과 포함 관계를 통해 개별 용어가 전체 아키텍처에서 어디에 자리하는지 짚어준다',
]

DIAGRAM_PURPOSE_TABLE = [
    '표 형태로 여러 항목을 나란히 배치하여 속성별 비교가 한눈에 가능하도록 정리한다',
    '행과 열의 격자 구조로 데이터 예시를 배열하여 실제 테이블이 어떻게 구성되는지 감각적으로 전달한다',
    '각 행이 하나의 레코드에 대응되도록 나열하여 관계형 테이블의 직관적인 생김새를 보여준다',
]

DIAGRAM_PURPOSE_GENERIC = [
    '개념의 구성 요소를 한 화면에 배치하여 상호 관계와 전체 윤곽을 요약해 보여준다',
    '글로만 읽으면 놓치기 쉬운 구조적 관계를 그림 한 장에 압축하여 전달한다',
    '관련 용어들이 서로 어떤 위치에 놓이는지 도식으로 보여, 독자가 머릿속에 개념 지도를 그릴 수 있도록 돕는다',
]

DIAGRAM_TAILS = [
    '독자는 세부 구문이나 수치보다 요소들 사이의 관계를 먼저 읽어내는 것이 이 시각 자료의 본래 사용법이다.',
    '이 도식을 본 뒤 이어지는 본문은 각 요소가 왜 그 자리에 놓였는지 하나씩 풀어 설명하는 구성을 따른다.',
    '중요한 것은 개별 기호의 형태가 아니라 요소들 사이에 어떤 관계가 성립하는가이며, 본문의 세부 설명은 바로 그 관계를 한 겹씩 벗겨 보여준다.',
    '같은 내용을 문장으로만 설명했다면 관계가 잘 드러나지 않았겠지만, 도식 덕분에 전체 지형을 먼저 파악한 뒤 세부로 들어갈 수 있게 된다.',
    '이 그림이 전달하는 핵심은 개별 상자의 이름이 아니라 그들을 잇는 구조이며, 이후 서술은 그 구조를 이론과 실무 맥락에서 재차 해설한다.',
]


def diagram_description(block: dict, feats: dict, rng: random.Random) -> str:
    sec = extract_section_intent(block['section'])
    chapter_topic, chapter_detail = STEP_TOPIC.get(block['chapterId'], ('', ''))
    gist = build_context_gist(block['context'])

    opener = pick(rng, DIAGRAM_OPENERS)
    if feats['has_tree']:
        purpose = pick(rng, DIAGRAM_PURPOSE_TREE)
    elif feats['has_arrow']:
        purpose = pick(rng, DIAGRAM_PURPOSE_ARROW)
    elif feats['has_table_grid']:
        purpose = pick(rng, DIAGRAM_PURPOSE_TABLE)
    elif feats['has_box']:
        purpose = pick(rng, DIAGRAM_PURPOSE_BOX)
    else:
        purpose = pick(rng, DIAGRAM_PURPOSE_GENERIC)

    topic_phrase = ''
    if chapter_topic:
        topic_phrase = f'{chapter_topic} 단원 중 \"{sec}\" 파트에서 '
    else:
        topic_phrase = f'\"{sec}\" 절에서 '

    para1 = f'{topic_phrase}{opener} {purpose}. '
    if gist:
        if not gist.endswith(('.', '。', '!', '?')):
            gist += '.'
        para1 += gist + ' '

    # Second paragraph: link to chapter topic
    if chapter_detail:
        focus_lines = [
            f'이 그림을 통해 독자는 {chapter_detail} 이라는 이 단원의 큰 주제가 구체적으로 어떤 모양을 가진 대상인지 감각적으로 파악할 수 있다.',
            f'도식의 역할은 {chapter_detail} 라는 학습 주제를 추상적인 용어가 아니라 눈에 보이는 형태로 먼저 체감하게 하는 것이다.',
            f'이어지는 설명은 {chapter_detail} 를 하나의 개념 체계로 이해시키기 위한 것이며, 이 그림은 그 체계의 뼈대를 미리 드러낸다.',
        ]
    else:
        focus_lines = [
            '이어지는 본문은 이 그림 속 요소를 하나씩 풀어 설명한다.',
            '그림에서 드러나는 전체 윤곽이 곧 이 단원에서 다룰 개념의 지형도이다.',
            '시각 자료는 이후 서술의 기준점이 되며, 본문은 이 기준점을 중심으로 세부를 채워 나간다.',
        ]
    focus = pick(rng, focus_lines)
    tail = pick(rng, DIAGRAM_TAILS)
    return _compose(para1, focus + ' ' + tail)


# ---------- 코드 (보조 블록) prose ----------

def code_description(block: dict, feats: dict, rng: random.Random) -> str:
    sec = extract_section_intent(block['section'])
    chapter_topic, chapter_detail = STEP_TOPIC.get(block['chapterId'], ('', ''))
    gist = build_context_gist(block['context'])

    if feats['is_bloom_list'] or feats['is_learning_goal']:
        openers = [
            '해당 단원이 학습자에게 요구하는 행동 목표를 Bloom 분류 (Remember · Understand · Apply · Analyze) 단계에 맞춰 열거하는 블록이다',
            '이 단원을 끝낸 뒤 학습자가 실제로 수행할 수 있어야 하는 행동을 단계별 동사로 정리해 둔 목록이다',
            '각 항목이 어느 수준의 이해를 요구하는지 인지 수준 태그와 함께 제시하여, 학습자가 스스로 도달 여부를 가늠할 수 있게 한다',
        ]
        tails = [
            '목록을 단순히 읽고 넘기기보다, 본문을 마친 뒤 각 항목을 실제로 수행해 보는 체크리스트로 활용할 때 가장 효과적이다.',
            '각 문장의 동사는 우연히 선택된 것이 아니라 Bloom 분류의 인지 수준을 드러내므로, 어느 단계에서 학습이 멈췄는지 진단하는 데 쓰인다.',
            '학습자는 이 항목들을 본문 학습 전 · 후에 각각 읽어 보고 이해도가 얼마나 깊어졌는지 스스로 비교할 수 있다.',
        ]
    elif feats['is_quiz']:
        openers = [
            '앞에서 학습한 내용을 스스로 인출해 보도록 구성된 확인 문항 블록이다',
            '정답을 즉시 공개하지 않고 먼저 생각을 유도한 뒤 비교하도록 설계된 자가 평가 문제이다',
            '독자가 수동적 읽기에서 능동적 인출 학습으로 전환하도록 돕는 간단한 퀴즈이다',
        ]
        tails = [
            '문제를 풀면서 어디에서 막히는지를 관찰하면, 본문에서 다시 확인해야 할 지점이 자연스럽게 드러난다.',
            '답을 맞히는 것보다 자기 언어로 설명해 보는 과정 자체가 중요한 학습이다.',
            '헷갈리는 문항이 있다면 본문으로 돌아가 해당 개념의 설명을 한 번 더 정독하는 것이 이 블록의 사용 순서이다.',
        ]
    elif feats['is_checklist']:
        openers = [
            '학습 완료 여부를 스스로 점검할 수 있도록 만든 체크리스트 블록이다',
            '단원을 마쳤을 때 독자가 실제로 설명할 수 있어야 하는 항목을 체크 박스로 나열한 구성이다',
            '자가 진단 용도로 제공되는 확인 목록이며, 모든 항목을 말로 설명할 수 있을 때 해당 단원의 학습이 끝난 것으로 간주한다',
        ]
        tails = [
            '체크되지 않은 항목이 남아 있다면 그 항목에 해당하는 본문 절을 다시 훑으라는 신호로 읽으면 된다.',
            '이 리스트의 핵심은 암기가 아니라 설명 가능성이며, 남에게 말로 풀어낼 수 있을 때 비로소 체크할 수 있다.',
            '모든 항목을 표시할 수 있게 되면 다음 단원으로 넘어가도 좋다는 의미이다.',
        ]
    elif feats['is_shell']:
        openers = [
            '자기 환경에서 MySQL 도구를 설치하거나 서버에 접속하기 위한 셸 명령을 보여주는 블록이다',
            '명령줄에서 그대로 따라 입력하면 학습 문서에 기술된 상태를 재현할 수 있는 실행 명령 모음이다',
            '패키지 관리자나 컨테이너 런타임을 통해 MySQL 환경을 구성하는 실제 명령 예시이다',
        ]
        tails = [
            '명령의 옵션과 경로를 훑으면 서버 · 클라이언트 · 포트 · 인증 방식이 어떻게 연결되는지 간접적으로 이해할 수 있다.',
            '각 플랫폼 (macOS · Linux · Docker) 마다 명령이 다르지만, 결과적으로 도달해야 하는 상태는 동일하다는 점을 읽어내는 것이 중요하다.',
            '옵션 플래그는 외우기보다 왜 그것이 필요한지, 없으면 어떤 상태가 되는지 되짚어 보면 기억에 오래 남는다.',
        ]
    else:
        openers = [
            '해당 절의 설명을 보완하는 보조 텍스트 블록으로, 용어 대응 · 절차 요약 · 핵심 정리 등을 담는다',
            '본문 서술이 길어질 때 흐트러지기 쉬운 정보를 한 곳에 모아 정리해 둔 요약 블록이다',
            '관련 개념들 사이의 대응 관계 또는 단계를 텍스트 형태로 묶어 보여주는 보조 블록이다',
        ]
        tails = [
            '본문을 앞뒤로 오가며 찾아야 할 사실을 한 번에 확인할 수 있도록 도와주는 구성이다.',
            '내용 자체보다 이런 블록을 만났을 때 "다시 돌아올 지점"으로 표시해 두고 활용하는 습관이 더 중요하다.',
            '문장이 아닌 목록이나 매핑 형태이므로, 필요할 때 빠르게 스캔하여 원하는 항목만 골라 읽을 수 있다.',
        ]

    opener = pick(rng, openers)
    tail = pick(rng, tails)
    topic_phrase = f'\"{sec}\" 절에 놓인 이 블록은 '
    para1 = f'{topic_phrase}{opener}. '
    if gist:
        if not gist.endswith(('.', '。', '!', '?')):
            gist += '.'
        para1 += gist + ' '
    # Slight contextual second line
    mid_options = [
        f'단원 전체 맥락에서 볼 때 이 블록은 {chapter_topic} 를 다루는 흐름 중 한 걸음에 해당한다.' if chapter_topic else '단원 전체 맥락에서 보면 이 블록은 하나의 정리 포인트 역할을 한다.',
        f'앞뒤 서술과 이어 읽으면 {chapter_detail} 라는 큰 주제가 어떤 세부 요소로 구성되는지 드러난다.' if chapter_detail else '앞뒤 서술과 이어 읽으면 단원 전체가 전달하려는 메시지가 더 분명해진다.',
        '본문만 읽었을 때 놓쳤을 법한 대응 관계를 이 블록이 한 번 더 정리해 주는 역할을 한다.',
    ]
    mid = pick(rng, mid_options)
    return _compose(para1, mid + ' ' + tail)


# ---------- 예제 코드 (SQL / Python 등) prose ----------

SQL_OP_INTRO = {
    'create_table': [
        'CREATE TABLE 문을 사용해 새 테이블의 스키마를 선언하는 예시이다',
        '컬럼 정의와 제약조건을 조합하여 테이블 구조를 고정시키는 DDL 예시이다',
        '테이블의 이름 · 컬럼 · 타입 · 제약조건을 한꺼번에 선언하여 데이터 저장소를 준비하는 예시이다',
    ],
    'create_index': [
        '특정 컬럼에 인덱스를 생성하여 조회 성능을 개선하는 예시이다',
        'CREATE INDEX 구문을 통해 쿼리가 풀 스캔 대신 인덱스 탐색을 사용하도록 유도하는 예시이다',
        '검색 빈도가 높은 컬럼에 보조 자료구조를 붙여 읽기 성능을 끌어올리는 예시이다',
    ],
    'create_view': [
        '복잡한 쿼리를 재사용 가능한 가상 테이블로 추상화하는 VIEW 생성 예시이다',
        '자주 쓰이는 조회 로직을 뷰로 정의해 애플리케이션 쪽 SQL 중복을 제거하는 예시이다',
        '뷰는 실제 데이터 저장이 아닌 쿼리 참조라는 특성을 보여주는 예시이다',
    ],
    'create_user': [
        '계정 자체를 생성하고 인증 방식을 지정하는 DCL 예시이다',
        '운영 환경에서 역할별 계정 분리를 구현하기 위한 CREATE USER 예시이다',
        '애플리케이션 · 관리자 · 읽기 전용 등 역할마다 다른 계정을 만드는 절차를 보여주는 예시이다',
    ],
    'alter': [
        '이미 생성된 테이블의 구조를 ALTER 로 변경하는 예시이다',
        '컬럼 추가 · 삭제 · 타입 변경 등 스키마 진화를 다루는 예시이다',
        '운영 중인 테이블에 새 제약조건이나 인덱스를 덧붙이는 절차를 보여주는 예시이다',
    ],
    'drop': [
        '더 이상 필요하지 않은 스키마 객체를 DROP 으로 제거하는 예시이다',
        '테이블 · 인덱스 · 뷰 등을 삭제하는 구문과 그에 따른 위험을 함께 보여주는 예시이다',
    ],
    'insert': [
        'INSERT 문으로 테이블에 새 행을 기록하는 예시이다',
        '단일 행 · 다중 행 · SELECT 기반 삽입 중 어느 방식이 상황에 맞는지 보여주는 예시이다',
        '필수 컬럼과 기본값 처리를 통해 안전하게 데이터를 투입하는 예시이다',
    ],
    'update': [
        'UPDATE ... SET ... WHERE 구조로 일부 행의 값을 수정하는 예시이다',
        'WHERE 절을 어떻게 좁혀야 의도한 레코드만 갱신되는지 보여주는 예시이다',
        '조건 누락 시 전체 행이 덮어써지는 사고를 예방하는 패턴을 담은 예시이다',
    ],
    'delete': [
        '조건에 맞는 행만 제거하는 DELETE FROM 예시이다',
        '전체 삭제 방지를 위해 WHERE 절과 트랜잭션을 함께 사용하는 안전 패턴 예시이다',
        '삭제 전 SELECT 로 대상 행을 미리 확인하는 절차를 포함한 예시이다',
    ],
    'select': [
        'SELECT 문으로 원하는 컬럼과 행을 조회하는 기본 예시이다',
        'WHERE · ORDER BY · 프로젝션을 조합하여 결과 집합을 다듬는 예시이다',
        '테이블에서 필요한 데이터만 뽑아내는 읽기 쿼리의 전형적인 구조를 보여주는 예시이다',
    ],
    'join': [
        'JOIN 을 통해 여러 테이블을 관계 기준으로 결합하는 예시이다',
        'INNER · LEFT · RIGHT 조인의 차이와 행 보존 여부를 비교할 수 있는 예시이다',
        'ON 절의 조건에 따라 결과 행이 어떻게 생성되는지 드러내는 예시이다',
    ],
    'subquery': [
        '서브쿼리를 사용하여 중간 결과를 만든 뒤 외부 쿼리가 그것을 참조하는 예시이다',
        '스칼라 · 행 · 테이블 · 상관 서브쿼리 중 어느 형태인지 구분하며 읽어야 하는 예시이다',
        '상위 쿼리가 하위 쿼리의 결과 집합에 의존하는 구조를 보여주는 예시이다',
    ],
    'cte': [
        'WITH 절 (CTE) 로 복잡한 쿼리를 단계별로 분해하여 가독성을 높이는 예시이다',
        '재귀 CTE 나 중간 집계 등 기능을 활용해 복잡한 로직을 단순하게 표현하는 예시이다',
        '중첩 서브쿼리를 이름 있는 단계로 풀어내어 유지보수하기 쉽게 만드는 예시이다',
    ],
    'group': [
        'GROUP BY 로 행을 묶고 집계 함수로 요약 값을 얻는 예시이다',
        'HAVING 은 WHERE 와 다르게 그룹 단위 조건이라는 점을 보여주는 예시이다',
        '카테고리별 · 일자별 등 차원을 기준으로 데이터를 축약해 보여주는 예시이다',
    ],
    'explain': [
        'EXPLAIN 으로 쿼리 실행 계획을 확인하는 예시이다',
        '인덱스 사용 여부 · 접근 방식 · 예상 행 수 등을 읽어 병목을 찾는 절차를 보여주는 예시이다',
        '쿼리를 바꾸기 전에 실행 계획부터 확인하는 튜닝 습관을 가르치는 예시이다',
    ],
    'transaction': [
        'START TRANSACTION · COMMIT · ROLLBACK 으로 트랜잭션 경계를 다루는 예시이다',
        '여러 DML 을 하나의 원자적 단위로 묶어 실패 시 전체를 되돌릴 수 있게 하는 예시이다',
        'SAVEPOINT 를 활용해 부분 롤백을 구현하는 기법을 보여주는 예시이다',
    ],
    'trigger': [
        'CREATE TRIGGER 로 특정 DML 이벤트 전후에 자동 실행 로직을 붙이는 예시이다',
        '이력 로깅 · 감사 추적 · 값 보정 등에 트리거가 쓰이는 전형적인 패턴 예시이다',
        'BEFORE · AFTER 타이밍에 따라 영향이 어떻게 달라지는지 비교해 볼 수 있는 예시이다',
    ],
    'procedure': [
        '저장 프로시저를 정의하여 서버 측에서 반복 로직을 실행하는 예시이다',
        '변수 · 제어문 · 커서를 활용해 배치 처리나 월별 정산 같은 절차를 캡슐화하는 예시이다',
        '클라이언트 왕복을 줄이고 서버 안에서 복잡한 흐름을 끝내는 방법을 보여주는 예시이다',
    ],
    'grant': [
        'GRANT · REVOKE 로 계정에 권한을 부여 · 회수하는 예시이다',
        '역할별 접근 범위를 세분화하여 운영 사고를 예방하는 권한 설계 예시이다',
        '최소 권한 원칙에 따라 계정마다 필요한 만큼만 허용하는 방식을 보여주는 예시이다',
    ],
    'window': [
        '윈도우 함수를 사용해 행 단위 계산을 유지하면서 순위 · 누적값 · 이전 · 이후 행을 참조하는 예시이다',
        'ROW_NUMBER · RANK · LAG · LEAD 등으로 그룹 내 위치 관련 정보를 함께 뽑아내는 예시이다',
        '집계를 위해 행을 합치지 않으면서도 집계 맥락을 얻을 수 있는 OVER 절 활용 예시이다',
    ],
    'generic': [
        'SQL 구문을 사용하여 특정 개념을 실제 쿼리로 구현하는 예시이다',
        '이론에서 설명한 동작이 실제 SQL 에서 어떤 형태로 표현되는지 보여주는 예시이다',
        '작성 가능한 최소 형태의 SQL 을 제시하여 개념을 손으로 재현해 볼 수 있게 하는 예시이다',
    ],
}

SQL_TAILS = [
    '이 코드의 가치는 문자열을 그대로 외우는 것이 아니라, 같은 요구를 받았을 때 어떤 절차로 구문을 조립해야 하는지 익히는 데 있다.',
    '구문 세부는 MySQL 버전마다 차이가 있지만, 여기서 보여주는 흐름은 대부분의 RDBMS 에서 공통적으로 통한다.',
    '독자는 예제를 그대로 복붙하기보다 각 절의 역할을 스스로 설명해 보며 따라 쓰는 방식으로 학습할 때 가장 많이 남는다.',
    '쿼리 자체보다 쿼리가 해결하려는 문제가 무엇인지, 왜 이 구조를 선택했는지 이해하는 것이 본래 학습 목표이다.',
    '비슷한 상황에서 이 패턴을 변형해 적용할 수 있는 감각이 잡히면, 이 예제가 의도한 지점에 도달한 것이다.',
]


def classify_sql_op(feats: dict) -> str:
    if feats['has_sql_trigger']:
        return 'trigger'
    if feats['has_sql_procedure']:
        return 'procedure'
    if feats['has_sql_cte']:
        return 'cte'
    if feats['has_sql_window']:
        return 'window'
    if feats['has_sql_explain']:
        return 'explain'
    if feats['has_sql_transaction']:
        return 'transaction'
    if feats['has_sql_grant']:
        return 'grant'
    if feats['has_sql_create_view']:
        return 'create_view'
    if feats['has_sql_create_index']:
        return 'create_index'
    if feats['has_sql_create_user']:
        return 'create_user'
    if feats['has_sql_create_table']:
        return 'create_table'
    if feats['has_sql_alter']:
        return 'alter'
    if feats['has_sql_drop']:
        return 'drop'
    if feats['has_sql_insert']:
        return 'insert'
    if feats['has_sql_update']:
        return 'update'
    if feats['has_sql_delete']:
        return 'delete'
    if feats['has_subquery']:
        return 'subquery'
    if feats['has_sql_join']:
        return 'join'
    if feats['has_sql_group'] or feats['has_sql_having']:
        return 'group'
    if feats['has_sql_select']:
        return 'select'
    return 'generic'


def example_code_description(block: dict, feats: dict, rng: random.Random) -> str:
    sec = extract_section_intent(block['section'])
    chapter_topic, chapter_detail = STEP_TOPIC.get(block['chapterId'], ('', ''))
    gist = build_context_gist(block['context'])
    lang = feats['lang']
    is_sql = lang in {'sql', 'mysql'} or any(feats[k] for k in (
        'has_sql_select', 'has_sql_create_table', 'has_sql_insert',
        'has_sql_update', 'has_sql_delete', 'has_sql_join', 'has_sql_group',
        'has_sql_explain', 'has_sql_transaction', 'has_sql_trigger',
        'has_sql_procedure', 'has_sql_grant', 'has_sql_create_view',
        'has_sql_create_index', 'has_sql_create_user', 'has_sql_alter',
        'has_sql_drop', 'has_sql_window', 'has_sql_cte',
    ))

    if is_sql:
        op = classify_sql_op(feats)
        opener = pick(rng, SQL_OP_INTRO[op])
        tail = pick(rng, SQL_TAILS)
    elif lang == 'python':
        openers = [
            '파일 시스템이나 외부 로직 쪽에서 동일한 문제를 다루면 어떻게 되는지 보여주기 위한 Python 예시이다',
            'DB 가 아닌 애플리케이션 코드에서 같은 요구를 처리할 때의 번거로움을 대비해 보여주는 Python 예시이다',
            '파이썬 스크립트 형태로 동일 시나리오를 구현하여 RDBMS 의 이점을 간접적으로 드러내는 예시이다',
        ]
        opener = pick(rng, openers)
        tails = [
            '문법 세부보다 "왜 이 작업을 SQL 로 옮겼을 때 훨씬 간결해지는가" 라는 대비 구도를 읽어내는 것이 이 블록의 사용법이다.',
            '이 코드는 SQL 대안으로 보여지는 경우가 많으며, 두 방식의 복잡도를 비교해 보면 RDBMS 의 설계 의도가 더 선명해진다.',
            '예제는 실행 환경마다 결과가 다를 수 있지만, 전달하려는 메시지는 동일한 문제를 다른 도구로 풀었을 때의 차이 그 자체이다.',
        ]
        tail = pick(rng, tails)
    else:
        openers = [
            f'{lang or "해당 언어"} 코드 형태로 관련 개념을 실행 가능한 표본으로 제시한 예시이다',
            f'{lang or "평문"} 블록을 사용해 개념을 구체적인 실행 단위로 옮겨 놓은 예시이다',
            '본문 설명을 구체적인 실행 단위로 번역해 놓은 실습용 코드 예시이다',
        ]
        opener = pick(rng, openers)
        tail = pick(rng, SQL_TAILS)

    topic_phrase = f'\"{sec}\" 절에 실린 이 예제 코드는 '
    para1 = f'{topic_phrase}{opener}. '
    if gist:
        if not gist.endswith(('.', '。', '!', '?')):
            gist += '.'
        para1 += gist + ' '

    mid_options = []
    if chapter_detail:
        mid_options.append(f'단원의 핵심 주제인 {chapter_detail} 가 실제 쿼리로 표현될 때 어떤 모양을 띠는지 이 예제가 구체적으로 드러낸다.')
        mid_options.append(f'이 예제는 {chapter_topic} 라는 단원 주제를 말로 이해하는 데 그치지 않고 손으로 확인할 수 있게 이어주는 다리 역할을 한다.')
    else:
        mid_options.append('추상적 설명을 손에 잡히는 코드로 연결해 주는 다리 역할이 이 예제의 기능이다.')
    mid_options.append('맥락 없이 구문만 따라 쓰기보다, 주변 설명과 함께 읽을 때 비로소 의도가 드러나도록 설계된 블록이다.')
    mid = pick(rng, mid_options)
    return _compose(para1, mid + ' ' + tail)


# ---------- 공통 유틸 ----------

def _compose(para1: str, para2: str) -> str:
    text = para1.strip() + '\n\n' + para2.strip()
    text = re.sub(r' +', ' ', text)
    # clamp length: aim for 200-500 characters, but allow slight overruns
    return text.strip()


def build_description(block: dict) -> str:
    # Deterministic randomness per block
    rng = random.Random(block['hash'])
    kind = block['kind']
    feats = detect_body_features(block['body'], block.get('language', ''))
    if kind == '다이어그램':
        return diagram_description(block, feats, rng)
    if kind == '예제 코드':
        return example_code_description(block, feats, rng)
    return code_description(block, feats, rng)


def main() -> int:
    with BLOCK_JSON.open(encoding='utf-8') as f:
        blocks = json.load(f)

    by_chapter: dict[str, list[dict]] = defaultdict(list)
    for b in blocks:
        by_chapter[b['chapterId']].append(b)

    OUT_ROOT.mkdir(parents=True, exist_ok=True)
    total = 0
    per_chapter = {}
    for chapter_id, items in by_chapter.items():
        out_path = OUT_ROOT / f'{chapter_id}.json'
        cache = {'chapterId': chapter_id, 'entries': {}}
        entries = cache['entries']
        for b in items:
            h = b['hash']
            if h in entries:
                continue
            desc = build_description(b)
            entries[h] = {'language': b.get('language', ''), 'description': desc}
            total += 1
        cache['entries'] = entries
        with out_path.open('w', encoding='utf-8', newline='\n') as f:
            json.dump(cache, f, ensure_ascii=False, indent=2)
            f.write('\n')
        per_chapter[chapter_id] = len(entries)

    print(f'TOTAL ENTRIES WRITTEN: {total}')
    for k, v in sorted(per_chapter.items()):
        print(f'  {k}: {v}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
