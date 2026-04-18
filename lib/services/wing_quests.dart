import '../data/models/quest_model.dart';

/// P0-5 NPC-6: 분관별 샘플 퀘스트.
///
/// Phase 1 설계 §5의 3단 구조(대화 → 학습 → 복귀)를 유지하되, 개인 P0
/// 단계에선 서사보단 "담당 챕터 학습 완료"를 퀘스트 완료 조건으로 사용한다.
/// JSON 자산 대신 코드 상수로 유지 — 팀 버전(P2)에서 외부화 검토.
class WingQuests {
  const WingQuests._();

  /// wingId → 샘플 퀘스트 1~2개.
  static const Map<String, List<Quest>> all = {
    'backend': [
      Quest(
        id: 'q_backend_spring_bean',
        title: 'Bean 생애 주기 탐험',
        description: '아르카누스가 의존성의 봉인을 풀어보라 한다. '
            'Spring Bean의 초기화·소멸 순서를 익힌 뒤 돌아와라.',
        npcId: 'wizard',
        requiredChapters: ['java-spring-step10_스프링_기본'],
        dialogueTree: DialogueTree(
          startNodeId: 'intro',
          nodes: [
            DialogueNode(
              id: 'intro',
              speakerName: '아르카누스',
              text: '젊은이여, 백엔드의 수수께끼를 풀 준비가 되었느냐?',
              choices: [
                DialogueChoice(
                  text: '시작하겠다',
                  nextNodeId: 'done',
                ),
                DialogueChoice(text: '다음에', nextNodeId: 'end'),
              ],
            ),
            DialogueNode(
              id: 'done',
              speakerName: '아르카누스',
              text: '좋다. Spring의 기본 챕터로 향하라. 완료 후 다시 오라.',
              choices: [],
            ),
            DialogueNode(
              id: 'end',
              speakerName: '아르카누스',
              text: '마음이 준비되면 돌아오라.',
              choices: [],
            ),
          ],
        ),
        reward: QuestReward(xp: 100, title: '봉인 해제자'),
        wingId: 'backend',
        relatedCategories: ['java-spring'],
      ),
    ],
    'frontend': [
      Quest(
        id: 'q_frontend_widget_tree',
        title: '톱니바퀴의 설계도',
        description: '코그윈이 위젯 트리의 구성을 이해하라고 한다. '
            'Flutter 기본 위젯 챕터를 완료해라.',
        npcId: 'mechanic',
        requiredChapters: ['flutter-step01_flutter_기본_위젯'],
        dialogueTree: DialogueTree(
          startNodeId: 'intro',
          nodes: [
            DialogueNode(
              id: 'intro',
              speakerName: '코그윈',
              text: '이 톱니바퀴가 어떻게 돌아가는지 알고 싶다면 말이지…',
              choices: [
                DialogueChoice(text: '알겠다', nextNodeId: 'end'),
              ],
            ),
            DialogueNode(
              id: 'end',
              speakerName: '코그윈',
              text: 'Flutter의 위젯들을 살피고 오라.',
              choices: [],
            ),
          ],
        ),
        reward: QuestReward(xp: 80),
        wingId: 'frontend',
        relatedCategories: ['flutter'],
      ),
    ],
    'database': [
      Quest(
        id: 'q_database_index',
        title: '인덱스의 연금술',
        description: '메르쿠리아가 MySQL 인덱스의 비법을 전수하려 한다.',
        npcId: 'alchemist',
        requiredChapters: ['mysql-mysql-step-03'],
        dialogueTree: DialogueTree(
          startNodeId: 'intro',
          nodes: [
            DialogueNode(
              id: 'intro',
              speakerName: '메르쿠리아',
              text: 'B+Tree의 층위를 꿰뚫고 오라.',
              choices: [
                DialogueChoice(text: '가겠다', nextNodeId: 'end'),
              ],
            ),
            DialogueNode(
              id: 'end',
              speakerName: '메르쿠리아',
              text: '돌아오면 인덱스 설계의 정수를 보여주지.',
              choices: [],
            ),
          ],
        ),
        reward: QuestReward(xp: 90),
        wingId: 'database',
        relatedCategories: ['mysql'],
      ),
    ],
    'architecture': [
      Quest(
        id: 'q_architecture_api_gateway',
        title: '관문의 수호',
        description: '모뉴멘타가 API Gateway 설계를 검증하라 한다. '
            'MSA Phase 4 Step 1 챕터를 완료해라.',
        npcId: 'architect',
        requiredChapters: ['msa-phase4-step1-api-gateway'],
        dialogueTree: DialogueTree(
          startNodeId: 'intro',
          nodes: [
            DialogueNode(
              id: 'intro',
              speakerName: '모뉴멘타',
              text: '대성당의 정문은 방어와 라우팅을 동시에 수행해야 한다.',
              choices: [
                DialogueChoice(text: '이해했다', nextNodeId: 'end'),
              ],
            ),
            DialogueNode(
              id: 'end',
              speakerName: '모뉴멘타',
              text: 'API Gateway 챕터에서 실마리를 찾아라.',
              choices: [],
            ),
          ],
        ),
        reward: QuestReward(xp: 120),
        wingId: 'architecture',
        relatedCategories: ['msa'],
      ),
    ],
  };

  static List<Quest> forWing(String wingId) => all[wingId] ?? const [];

  /// [completedChapters] 기준으로 quest 상태를 재계산한 목록.
  static List<Quest> withStatus(
    String wingId,
    Set<String> completedChapters,
  ) {
    return forWing(wingId).map((q) {
      if (q.requiredChapters.isEmpty) return q;
      final done =
          q.requiredChapters.every((c) => completedChapters.contains(c));
      return q.copyWith(
        status: done ? QuestStatus.completed : QuestStatus.inProgress,
      );
    }).toList(growable: false);
  }
}
