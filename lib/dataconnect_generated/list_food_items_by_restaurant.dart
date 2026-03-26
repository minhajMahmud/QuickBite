part of 'generated.dart';

class ListFoodItemsByRestaurantVariablesBuilder {
  String restaurantId;

  final FirebaseDataConnect _dataConnect;
  ListFoodItemsByRestaurantVariablesBuilder(
    this._dataConnect, {
    required this.restaurantId,
  });
  Deserializer<ListFoodItemsByRestaurantData> dataDeserializer =
      (dynamic json) =>
          ListFoodItemsByRestaurantData.fromJson(jsonDecode(json));
  Serializer<ListFoodItemsByRestaurantVariables> varsSerializer =
      (ListFoodItemsByRestaurantVariables vars) => jsonEncode(vars.toJson());
  Future<
      QueryResult<ListFoodItemsByRestaurantData,
          ListFoodItemsByRestaurantVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListFoodItemsByRestaurantData, ListFoodItemsByRestaurantVariables>
      ref() {
    ListFoodItemsByRestaurantVariables vars =
        ListFoodItemsByRestaurantVariables(
      restaurantId: restaurantId,
    );
    return _dataConnect.query(
        "ListFoodItemsByRestaurant", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListFoodItemsByRestaurantFoodItems {
  final String id;
  final String name;
  final double price;
  final String availability;
  final double rating;
  final int reviewCount;
  ListFoodItemsByRestaurantFoodItems.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']),
        name = nativeFromJson<String>(json['name']),
        price = nativeFromJson<double>(json['price']),
        availability = nativeFromJson<String>(json['availability']),
        rating = nativeFromJson<double>(json['rating']),
        reviewCount = nativeFromJson<int>(json['reviewCount']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListFoodItemsByRestaurantFoodItems otherTyped =
        other as ListFoodItemsByRestaurantFoodItems;
    return id == otherTyped.id &&
        name == otherTyped.name &&
        price == otherTyped.price &&
        availability == otherTyped.availability &&
        rating == otherTyped.rating &&
        reviewCount == otherTyped.reviewCount;
  }

  @override
  int get hashCode => Object.hashAll([
        id.hashCode,
        name.hashCode,
        price.hashCode,
        availability.hashCode,
        rating.hashCode,
        reviewCount.hashCode
      ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['price'] = nativeToJson<double>(price);
    json['availability'] = nativeToJson<String>(availability);
    json['rating'] = nativeToJson<double>(rating);
    json['reviewCount'] = nativeToJson<int>(reviewCount);
    return json;
  }

  ListFoodItemsByRestaurantFoodItems({
    required this.id,
    required this.name,
    required this.price,
    required this.availability,
    required this.rating,
    required this.reviewCount,
  });
}

@immutable
class ListFoodItemsByRestaurantData {
  final List<ListFoodItemsByRestaurantFoodItems> foodItems;
  ListFoodItemsByRestaurantData.fromJson(dynamic json)
      : foodItems = (json['foodItems'] as List<dynamic>)
            .map((e) => ListFoodItemsByRestaurantFoodItems.fromJson(e))
            .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListFoodItemsByRestaurantData otherTyped =
        other as ListFoodItemsByRestaurantData;
    return foodItems == otherTyped.foodItems;
  }

  @override
  int get hashCode => foodItems.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['foodItems'] = foodItems.map((e) => e.toJson()).toList();
    return json;
  }

  ListFoodItemsByRestaurantData({
    required this.foodItems,
  });
}

@immutable
class ListFoodItemsByRestaurantVariables {
  final String restaurantId;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListFoodItemsByRestaurantVariables.fromJson(Map<String, dynamic> json)
      : restaurantId = nativeFromJson<String>(json['restaurantId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListFoodItemsByRestaurantVariables otherTyped =
        other as ListFoodItemsByRestaurantVariables;
    return restaurantId == otherTyped.restaurantId;
  }

  @override
  int get hashCode => restaurantId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['restaurantId'] = nativeToJson<String>(restaurantId);
    return json;
  }

  ListFoodItemsByRestaurantVariables({
    required this.restaurantId,
  });
}
