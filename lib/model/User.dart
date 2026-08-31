// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';
part 'User.g.dart';

@JsonSerializable()
class UserModel extends Object {
  String? username;
  String? email;
  String? manager_id;
  dynamic cpanel_privileges;
  String? privileges;
  String? privileges_imei;
  String? privileges_marker;
  String? privileges_route;
  String? privileges_zone;
  bool? privileges_dashboard;
  bool? privileges_history;
  bool? privileges_reports;
  bool? privileges_tasks;
  bool? privileges_rilogbook;
  bool? privileges_dtc;
  bool? privileges_maintenance;
  bool? privileges_expenses;
  bool? privileges_object_control;
  bool? privileges_image_gallery;
  bool? privileges_chat;
  bool? privileges_subaccounts;
  bool? billing;
  String? obj_add;
  String? obj_limit;
  String? obj_limit_num;
  String? obj_days;
  String? obj_days_dt;
  String? obj_edit;
  String? obj_delete;
  String? obj_history_clear;
  String? chat_notify;
  String? map_sp;
  String? map_is;
  String? map_rc;
  String? map_rhc;
  String? map_ocp;
  Map<String, dynamic>? groups_collapsed;
  String? od;
  Map<String, dynamic>? ohc;
  String? datalist;
  String? datalist_items;
  String? push_notify_desktop;
  String? push_notify_mobile;
  dynamic push_notify_mobile_interval;
  String? sms_gateway;
  String? sms_gateway_type;
  String? sms_gateway_url;
  String? sms_gateway_identifier;
  int? sms_gateway_total_in_queue;
  String? startup_tab;
  String? language;
  String? unit_distance;
  String? unit_capacity;
  String? unit_temperature;
  String? currency;
  String? timezone;
  String? dst;
  String? dst_start;
  String? dst_end;
  Map<String, dynamic>? info;
  String? usage_email_daily;
  String? usage_sms_daily;
  String? usage_api_daily;
  String? usage_email_daily_cnt;
  String? usage_sms_daily_cnt;
  String? usage_api_daily_cnt;
  String? cards;

  UserModel({
    this.username,
    this.email,
    this.manager_id,
    this.cpanel_privileges,
    this.privileges,
    this.privileges_imei,
    this.privileges_marker,
    this.privileges_route,
    this.privileges_zone,
    this.privileges_dashboard,
    this.privileges_history,
    this.privileges_reports,
    this.privileges_tasks,
    this.privileges_rilogbook,
    this.privileges_dtc,
    this.privileges_maintenance,
    this.privileges_expenses,
    this.privileges_object_control,
    this.privileges_image_gallery,
    this.privileges_chat,
    this.privileges_subaccounts,
    this.billing,
    this.obj_add,
    this.obj_limit,
    this.obj_limit_num,
    this.obj_days,
    this.obj_days_dt,
    this.obj_edit,
    this.obj_delete,
    this.obj_history_clear,
    this.chat_notify,
    this.map_sp,
    this.map_is,
    this.map_rc,
    this.map_rhc,
    this.map_ocp,
    this.groups_collapsed,
    this.od,
    this.ohc,
    this.datalist,
    this.datalist_items,
    this.push_notify_desktop,
    this.push_notify_mobile,
    this.push_notify_mobile_interval,
    this.sms_gateway,
    this.sms_gateway_type,
    this.sms_gateway_url,
    this.sms_gateway_identifier,
    this.sms_gateway_total_in_queue,
    this.startup_tab,
    this.language,
    this.unit_distance,
    this.unit_capacity,
    this.unit_temperature,
    this.currency,
    this.timezone,
    this.dst,
    this.dst_start,
    this.dst_end,
    this.info,
    this.usage_email_daily,
    this.usage_sms_daily,
    this.usage_api_daily,
    this.usage_email_daily_cnt,
    this.usage_sms_daily_cnt,
    this.usage_api_daily_cnt,
    this.cards,
  });

  factory UserModel.fromJson(Map<String, dynamic> data) => _$UserModelFromJson(data);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Traccar Session & User API Parser (/api/session, /api/users, /api/users/{id})
  factory UserModel.fromTraccarUser(Map<String, dynamic> traccarJson) {
    final attributes = traccarJson['attributes'] is Map<String, dynamic>
        ? traccarJson['attributes'] as Map<String, dynamic>
        : <String, dynamic>{};

    bool isAdmin = traccarJson['administrator'] == true;
    bool isReadonly = traccarJson['readonly'] == true;

    return UserModel(
      username: traccarJson['name']?.toString() ?? traccarJson['email']?.toString() ?? '',
      email: traccarJson['email']?.toString() ?? '',
      manager_id: traccarJson['userLimit']?.toString() ?? '0',
      privileges: isAdmin ? 'admin' : 'user',
      privileges_dashboard: true,
      privileges_history: true,
      privileges_reports: !isReadonly,
      privileges_tasks: true,
      privileges_maintenance: true,
      privileges_expenses: true,
      privileges_object_control: !isReadonly,
      privileges_image_gallery: true,
      privileges_chat: true,
      privileges_subaccounts: isAdmin,
      billing: !isReadonly,
      obj_add: isReadonly ? 'false' : 'true',
      obj_limit: traccarJson['deviceLimit']?.toString() ?? '-1',
      obj_limit_num: traccarJson['deviceLimit']?.toString() ?? '-1',
      obj_edit: isReadonly ? 'false' : 'true',
      obj_delete: isReadonly ? 'false' : 'true',
      language: attributes['language']?.toString() ?? 'en',
      unit_distance: attributes['distanceUnit']?.toString() ?? 'km',
      unit_capacity: attributes['volumeUnit']?.toString() ?? 'liter',
      unit_temperature: attributes['temperatureUnit']?.toString() ?? 'celsius',
      timezone: attributes['timezone']?.toString() ?? 'UTC',
      currency: attributes['currency']?.toString() ?? 'PKR',
      info: attributes,
    );
  }

  /// Exports UserModel to Traccar REST API compatible User payload (POST /api/users, PUT /api/users/{id})
  Map<String, dynamic> toTraccarUserPayload({int? userId, String? password}) {
    Map<String, dynamic> payload = {
      "name": username ?? '',
      "email": email ?? '',
      "readonly": billing == false,
      "administrator": privileges == 'admin',
      "deviceLimit": int.tryParse(obj_limit ?? '-1') ?? -1,
      "attributes": {
        "language": language ?? 'en',
        "distanceUnit": unit_distance ?? 'km',
        "volumeUnit": unit_capacity ?? 'liter',
        "temperatureUnit": unit_temperature ?? 'celsius',
        "timezone": timezone ?? 'UTC',
        "currency": currency ?? 'PKR',
        ...?info,
      }
    };

    if (userId != null) {
      payload["id"] = userId;
    }

    if (password != null && password.isNotEmpty) {
      payload["password"] = password;
    }

    return payload;
  }
}
