import 'dart:convert';

String imagesModelToJson(ImagesModel data) => json.encode(data.toJson());

class ImagesModel {
  ImagesModel({
    this.page,
    this.total,
    this.records,
    this.rows,
  });

  String? page;
  int? total;
  int? records;
  List<Row>? rows;

  /// Original JSON Factory (Safeguarded against null pointer & type mismatch errors)
  factory ImagesModel.fromJson(Map<String, dynamic> json) => ImagesModel(
        page: json["page"]?.toString(),
        total: json["total"] is int ? json["total"] : int.tryParse(json["total"]?.toString() ?? '1'),
        records: json["records"] is int ? json["records"] : int.tryParse(json["records"]?.toString() ?? '0'),
        rows: json["rows"] != null && json["rows"] is List
            ? List<Row>.from(json["rows"].map((x) => Row.fromJson(x)))
            : [],
      );

  /// Traccar REST API Parser for image history (/api/positions or device media)
  factory ImagesModel.fromTraccarPositions(List<dynamic> positionsList, {String baseUrl = ''}) {
    List<Row> parsedRows = [];
    for (var item in positionsList) {
      if (item is Map<String, dynamic>) {
        var attributes = item['attributes'] is Map<String, dynamic> ? item['attributes'] : {};
        if (attributes.containsKey('image') || attributes.containsKey('file') || attributes.containsKey('jpeg')) {
          parsedRows.add(Row.fromTraccarPosition(item, baseUrl: baseUrl));
        }
      }
    }

    return ImagesModel(
      page: "1",
      total: 1,
      records: parsedRows.length,
      rows: parsedRows,
    );
  }

  Map<String, dynamic> toJson() => {
        "page": page,
        "total": total,
        "records": records,
        "rows": rows != null ? List<dynamic>.from(rows!.map((x) => x.toJson())) : [],
      };
}

class Row {
  Row({
    this.id,
    this.cell,
  });

  String? id;
  List<String>? cell;

  /// Original JSON Factory (Safeguarded against null pointer)
  factory Row.fromJson(Map<String, dynamic> json) => Row(
        id: json["id"]?.toString(),
        cell: json["cell"] != null && json["cell"] is List
            ? List<String>.from(json["cell"].map((x) => x?.toString() ?? ''))
            : [],
      );

  /// Traccar REST API Parser for individual position photo/media attributes
  factory Row.fromTraccarPosition(Map<String, dynamic> positionJson, {String baseUrl = ''}) {
    String posId = positionJson['id']?.toString() ?? '';
    var attributes = positionJson['attributes'] is Map<String, dynamic> ? positionJson['attributes'] : {};
    
    String imageName = attributes['image']?.toString() ?? attributes['file']?.toString() ?? attributes['jpeg']?.toString() ?? '';
    
    // Construct absolute URL for Traccar media or server files
    String fullImageUrl = imageName.startsWith('http')
        ? imageName
        : '$baseUrl/api/media/$imageName';

    String fixTime = positionJson['fixTime']?.toString() ?? positionJson['serverTime']?.toString() ?? '';
    String lat = positionJson['latitude']?.toString() ?? '0.0';
    String lng = positionJson['longitude']?.toString() ?? '0.0';

    return Row(
      id: posId,
      cell: [
        posId,        // Cell 0: Position/Image ID
        imageName,    // Cell 1: Image Filename
        fullImageUrl, // Cell 2: Full Accessible Image URL
        fixTime,      // Cell 3: Capture Timestamp
        lat,          // Cell 4: Latitude
        lng,          // Cell 5: Longitude
      ],
    );
  }

  /// Traccar Device Image helper endpoint builder (/api/devices/{id}/image)
  factory Row.fromTraccarDeviceImage(int deviceId, {String baseUrl = ''}) {
    String imageUrl = '$baseUrl/api/devices/$deviceId/image';
    return Row(
      id: deviceId.toString(),
      cell: [
        deviceId.toString(),
        'device_$deviceId.jpg',
        imageUrl,
        DateTime.now().toIso8601String(),
        '0.0',
        '0.0',
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "cell": cell != null ? List<dynamic>.from(cell!.map((x) => x)) : [],
      };
}
