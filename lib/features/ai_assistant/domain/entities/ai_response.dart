import 'package:equatable/equatable.dart';
import 'package:doc_sense/features/ai_assistant/domain/entities/ai_action_type.dart';

class AiResponse extends Equatable {
  final AiActionType actionType;
  final String content;

  const AiResponse({required this.actionType, required this.content});

  @override
  List<Object?> get props => [actionType, content];
}
