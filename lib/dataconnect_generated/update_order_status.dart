part of 'generated.dart';

class UpdateOrderStatusVariablesBuilder {
  String orderId;
  String orderStatus;

  final FirebaseDataConnect _dataConnect;
  UpdateOrderStatusVariablesBuilder(
    this._dataConnect, {
    required this.orderId,
    required this.orderStatus,
  });
  Deserializer<UpdateOrderStatusData> dataDeserializer =
      (dynamic json) => UpdateOrderStatusData.fromJson(jsonDecode(json));
  Serializer<UpdateOrderStatusVariables> varsSerializer =
      (UpdateOrderStatusVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateOrderStatusData, UpdateOrderStatusVariables>>
      execute() {
    return ref().execute();
  }

  MutationRef<UpdateOrderStatusData, UpdateOrderStatusVariables> ref() {
    UpdateOrderStatusVariables vars = UpdateOrderStatusVariables(
      orderId: orderId,
      orderStatus: orderStatus,
    );
    return _dataConnect.mutation(
        "UpdateOrderStatus", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateOrderStatusOrderUpdate {
  final String id;
  UpdateOrderStatusOrderUpdate.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateOrderStatusOrderUpdate otherTyped =
        other as UpdateOrderStatusOrderUpdate;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateOrderStatusOrderUpdate({
    required this.id,
  });
}

@immutable
class UpdateOrderStatusData {
  final UpdateOrderStatusOrderUpdate? order_update;
  UpdateOrderStatusData.fromJson(dynamic json)
      : order_update = json['order_update'] == null
            ? null
            : UpdateOrderStatusOrderUpdate.fromJson(json['order_update']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateOrderStatusData otherTyped = other as UpdateOrderStatusData;
    return order_update == otherTyped.order_update;
  }

  @override
  int get hashCode => order_update.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (order_update != null) {
      json['order_update'] = order_update!.toJson();
    }
    return json;
  }

  UpdateOrderStatusData({
    this.order_update,
  });
}

@immutable
class UpdateOrderStatusVariables {
  final String orderId;
  final String orderStatus;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateOrderStatusVariables.fromJson(Map<String, dynamic> json)
      : orderId = nativeFromJson<String>(json['orderId']),
        orderStatus = nativeFromJson<String>(json['orderStatus']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateOrderStatusVariables otherTyped =
        other as UpdateOrderStatusVariables;
    return orderId == otherTyped.orderId &&
        orderStatus == otherTyped.orderStatus;
  }

  @override
  int get hashCode => Object.hashAll([orderId.hashCode, orderStatus.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orderId'] = nativeToJson<String>(orderId);
    json['orderStatus'] = nativeToJson<String>(orderStatus);
    return json;
  }

  UpdateOrderStatusVariables({
    required this.orderId,
    required this.orderStatus,
  });
}
