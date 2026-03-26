part of 'generated.dart';

class ListRestaurantsVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  ListRestaurantsVariablesBuilder(
    this._dataConnect,
  );
  Deserializer<ListRestaurantsData> dataDeserializer =
      (dynamic json) => ListRestaurantsData.fromJson(jsonDecode(json));

  Future<QueryResult<ListRestaurantsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListRestaurantsData, void> ref() {
    return _dataConnect.query(
        "ListRestaurants", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListRestaurantsRestaurants {
  final String id;
  final String name;
  final String? cuisine;
  final double rating;
  final double deliveryFee;
  final String status;
  final bool isApproved;
  ListRestaurantsRestaurants.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']),
        name = nativeFromJson<String>(json['name']),
        cuisine = json['cuisine'] == null
            ? null
            : nativeFromJson<String>(json['cuisine']),
        rating = nativeFromJson<double>(json['rating']),
        deliveryFee = nativeFromJson<double>(json['deliveryFee']),
        status = nativeFromJson<String>(json['status']),
        isApproved = nativeFromJson<bool>(json['isApproved']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListRestaurantsRestaurants otherTyped =
        other as ListRestaurantsRestaurants;
    return id == otherTyped.id &&
        name == otherTyped.name &&
        cuisine == otherTyped.cuisine &&
        rating == otherTyped.rating &&
        deliveryFee == otherTyped.deliveryFee &&
        status == otherTyped.status &&
        isApproved == otherTyped.isApproved;
  }

  @override
  int get hashCode => Object.hashAll([
        id.hashCode,
        name.hashCode,
        cuisine.hashCode,
        rating.hashCode,
        deliveryFee.hashCode,
        status.hashCode,
        isApproved.hashCode
      ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    if (cuisine != null) {
      json['cuisine'] = nativeToJson<String?>(cuisine);
    }
    json['rating'] = nativeToJson<double>(rating);
    json['deliveryFee'] = nativeToJson<double>(deliveryFee);
    json['status'] = nativeToJson<String>(status);
    json['isApproved'] = nativeToJson<bool>(isApproved);
    return json;
  }

  ListRestaurantsRestaurants({
    required this.id,
    required this.name,
    this.cuisine,
    required this.rating,
    required this.deliveryFee,
    required this.status,
    required this.isApproved,
  });
}

@immutable
class ListRestaurantsData {
  final List<ListRestaurantsRestaurants> restaurants;
  ListRestaurantsData.fromJson(dynamic json)
      : restaurants = (json['restaurants'] as List<dynamic>)
            .map((e) => ListRestaurantsRestaurants.fromJson(e))
            .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListRestaurantsData otherTyped = other as ListRestaurantsData;
    return restaurants == otherTyped.restaurants;
  }

  @override
  int get hashCode => restaurants.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['restaurants'] = restaurants.map((e) => e.toJson()).toList();
    return json;
  }

  ListRestaurantsData({
    required this.restaurants,
  });
}
