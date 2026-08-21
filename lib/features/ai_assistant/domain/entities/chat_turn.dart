/// One message in an ask-the-document conversation. Sent back with the next
/// question so follow-ups like "explain that again" have something to refer to.
class ChatTurn {
  final bool fromUser;
  final String text;

  const ChatTurn({required this.fromUser, required this.text});
}
