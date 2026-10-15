import 'journey_activity_evidence.dart';
import 'journey_good_habits.dart';
import 'journey_message_adapter.dart';

class JourneyMessageEvidence {
  const JourneyMessageEvidence(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
}

class JourneyGoodHabitsPipeline {
  const JourneyGoodHabitsPipeline();

  JourneyGoodHabitsSummary analyze(
    String childId,
    Iterable<JourneyMessageEvidence> messages,
  ) {
    const adapter = JourneyMessageAdapter();
    return const JourneyGoodHabitsAnalyzer().analyze(
      messages
          .map(
            (m) => adapter.activityFor(
              messageId: m.id,
              childId: childId,
              data: m.data,
            ),
          )
          .whereType<JourneyActivityRecord>(),
    );
  }
}
