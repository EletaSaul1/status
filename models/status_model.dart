class StatusModel {
  final String path;
  final DateTime dateModified;
  final bool isVideo;
  final String appSource;
  bool isFavorite;
  final String mediaType;

  StatusModel({
    required this.path,
    required this.dateModified,
    required this.isVideo,
    required this.appSource,
    this.isFavorite = false,
    required this.mediaType,
  });

  bool get isImage => !isVideo;

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'dateModified': dateModified.millisecondsSinceEpoch,
      'isVideo': isVideo,
      'appSource': appSource,
      'isFavorite': isFavorite,
      'mediaType': mediaType,
    };
  }

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      path: map['path'] as String,
      dateModified:
          DateTime.fromMillisecondsSinceEpoch(map['dateModified'] as int),
      isVideo: map['isVideo'] as bool,
      appSource: map['appSource'] as String,
      isFavorite: map['isFavorite'] as bool? ?? false,
      mediaType: map['mediaType'] as String,
    );
  }
}
