enum NotificationMode {
  none,
  vibrationOnly,
  soundOnly;

  int get value {
    switch (this) {
      case NotificationMode.none:
        return 0;
      case NotificationMode.vibrationOnly:
        return 1;
      case NotificationMode.soundOnly:
        return 2;
    }
  }

  static NotificationMode fromValue(int value) {
    switch (value) {
      case 0:
        return NotificationMode.none;
      case 1:
        return NotificationMode.vibrationOnly;
      case 2:
        return NotificationMode.soundOnly;
      default:
        return NotificationMode
            .soundOnly; // Default to sound only for backward compatibility
    }
  }
}
