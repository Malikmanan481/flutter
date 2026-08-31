class CommandHistory {
  CommandHistory({
    this.page,
    this.records,
    this.rows,
  });

  int? page;
  int? records;
  List<Row>? rows;

  /// Original JSON Factory (Safeguarded against Null & type mismatch errors)
  factory CommandHistory.fromJson(Map<String, dynamic> json) => CommandHistory(
        page: json["page"] is int ? json["page"] : int.tryParse(json["page"]?.toString() ?? '1'),
        records: json["records"] is int ? json["records"] : int.tryParse(json["records"]?.toString() ?? '0'),
        rows: json["rows"] != null && json["rows"] is List
            ? List<Row>.from(json["rows"].map((x) => Row.fromJson(x)))
            : [],
      );

  /// Traccar REST API Parser (/api/commands list response)
  factory CommandHistory.fromTraccarList(List<dynamic> jsonList) {
    List<Row> parsedRows = [];
    for (var item in jsonList) {
      if (item is Map<String, dynamic>) {
        parsedRows.add(Row.fromTraccarJson(item));
      }
    }
    return CommandHistory(
      page: 1,
      records: parsedRows.length,
      rows: parsedRows,
    );
  }

  Map<String, dynamic> toJson() => {
        "page": page,
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

  /// Traccar REST API Parser for individual command object (/api/commands)
  factory Row.fromTraccarJson(Map<String, dynamic> json) {
    String commandId = json['id']?.toString() ?? '';
    String commandType = json['type']?.toString() ?? json['description']?.toString() ?? 'Custom Command';
    String deviceId = json['deviceId']?.toString() ?? '';
    String status = json['attributes']?['result']?.toString() ?? json['status']?.toString() ?? 'Executed';
    String time = json['eventTime']?.toString() ?? json['serverTime']?.toString() ?? '';

    return Row(
      id: commandId,
      cell: [
        commandId,   // Cell index 0: Command ID
        commandType, // Cell index 1: Command Type (e.g. engineStop / engineResume)
        deviceId,    // Cell index 2: Device ID
        status,      // Cell index 3: Execution Result / Status
        time,        // Cell index 4: Sent / Event Time
      ],
    );
  }

  /// Convert to Traccar Command JSON format (To POST /api/commands/send)
  Map<String, dynamic> toTraccarCommandJson({required int deviceId, required String type}) => {
        "id": id != null ? int.tryParse(id!) : 0,
        "deviceId": deviceId,
        "type": type,
        "textChannel": false,
        "attributes": {},
      };

  Map<String, dynamic> toJson() => {
        "id": id,
        "cell": cell != null ? List<dynamic>.from(cell!.map((x) => x)) : [],
      };
}
