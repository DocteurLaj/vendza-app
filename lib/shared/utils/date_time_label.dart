String vendzaDateTimeLabel(DateTime value, {DateTime? now}) {
  final local = value.toLocal();
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final day = DateTime(local.year, local.month, local.day);
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  final delta = today.difference(day).inDays;
  if (delta == 0) return 'Aujourd’hui · $time';
  if (delta == 1) return 'Hier · $time';
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} · $time';
}
