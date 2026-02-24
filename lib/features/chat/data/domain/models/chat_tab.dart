/// Enum representing the chat tab categories.
///
/// - [prime]: Priority inbox. All new messages from uncategorized contacts land here.
/// - [chat]: Historical archive. Chats move here after being opened in Prime.
/// - [vip]: Manually categorized VIP contacts with priority notifications.
/// - [biz]: Manually categorized business contacts.
/// - [ai]: AI assistant tab (coming soon).
enum ChatTab {
  prime,
  chat,
  vip,
  biz,
  ai;

  /// Returns the Firestore string value for this tab.
  String get value => name;

  /// Creates a [ChatTab] from a Firestore string value.
  /// Defaults to [ChatTab.prime] if the value is unknown.
  static ChatTab fromString(String? value) {
    return ChatTab.values.firstWhere(
      (tab) => tab.name == value,
      orElse: () => ChatTab.prime,
    );
  }

  /// Translation key for display label.
  String get translationKey {
    switch (this) {
      case ChatTab.prime:
        return 'web.chat.tab_prime';
      case ChatTab.chat:
        return 'web.chat.tab_chat';
      case ChatTab.vip:
        return 'web.chat.tab_vip';
      case ChatTab.biz:
        return 'web.chat.tab_biz';
      case ChatTab.ai:
        return 'web.chat.tab_ai';
    }
  }

  /// Icon for each tab.
  String get iconName {
    switch (this) {
      case ChatTab.prime:
        return 'inbox';
      case ChatTab.chat:
        return 'chat';
      case ChatTab.vip:
        return 'star';
      case ChatTab.biz:
        return 'business';
      case ChatTab.ai:
        return 'smart_toy';
    }
  }

  /// Whether this tab allows manual assignment by the user.
  bool get isManuallyAssignable =>
      this == ChatTab.vip || this == ChatTab.biz;

  /// Whether this tab is functional (not coming soon).
  bool get isFunctional => this != ChatTab.ai;
}
