String getTimeNow() {
  final now = DateTime.now();
  return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
}
