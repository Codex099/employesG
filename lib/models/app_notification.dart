/// Represents a single collaborative notification fetched from Google Sheets.
class AppNotification {
  final String id;
  final String type;      // e.g. 'absence_added', 'absence_removed'
  final String title;
  final String message;
  final String author;    // username who triggered the event
  final int timestamp;    // ms since epoch

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.author,
    required this.timestamp,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id:        map['id']?.toString()      ?? '',
      type:      map['type']?.toString()    ?? 'info',
      title:     map['title']?.toString()   ?? '',
      message:   map['message']?.toString() ?? '',
      author:    map['author']?.toString()  ?? '',
      timestamp: map['timestamp'] is int
          ? map['timestamp'] as int
          : int.tryParse(map['timestamp']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'id':        id,
    'type':      type,
    'title':     title,
    'message':   message,
    'author':    author,
    'timestamp': timestamp,
  };
}
