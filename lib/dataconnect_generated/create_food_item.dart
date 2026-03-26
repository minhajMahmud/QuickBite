part of 'generated.dart';

class CreateFoodItemVariablesBuilder {
  String id;
  String restaurantId;
  String categoryId;
  String name;
  String description;
  double price;
  String image;
  bool isPopular;
  String availability;

  final FirebaseDataConnect _dataConnect;
  CreateFoodItemVariablesBuilder(
    this._dataConnect, {
    required this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.isPopular,
    required this.availability,
  });
  Deserializer<CreateFoodItemData> dataDeserializer =
      (dynamic json) => CreateFoodItemData.fromJson(jsonDecode(json));
  Serializer<CreateFoodItemVariables> varsSerializer =
      (CreateFoodItemVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateFoodItemData, CreateFoodItemVariables>>
      execute() {
    return ref().execute();
  }

  MutationRef<CreateFoodItemData, CreateFoodItemVariables> ref() {
    CreateFoodItemVariables vars = CreateFoodItemVariables(
      id: id,
      restaurantId: restaurantId,
      categoryId: categoryId,
      name: name,
      description: description,
      price: price,
      image: image,
      isPopular: isPopular,
      availability: availability,
    );
    return _dataConnect.mutation(
        "CreateFoodItem", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateFoodItemFoodItemInsert {
  final String id;
  CreateFoodItemFoodItemInsert.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateFoodItemFoodItemInsert otherTyped =
        other as CreateFoodItemFoodItemInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateFoodItemFoodItemInsert({
    required this.id,
  });
}

@immutable
class CreateFoodItemData {
  final CreateFoodItemFoodItemInsert foodItem_insert;
  CreateFoodItemData.fromJson(dynamic json)
      : foodItem_insert =
            CreateFoodItemFoodItemInsert.fromJson(json['foodItem_insert']);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateFoodItemData otherTyped = other as CreateFoodItemData;
    return foodItem_insert == otherTyped.foodItem_insert;
  }

  @override
  int get hashCode => foodItem_insert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['foodItem_insert'] = foodItem_insert.toJson();
    return json;
  }

  CreateFoodItemData({
    required this.foodItem_insert,
  });
}

@immutable
class CreateFoodItemVariables {
  final String id;
  final String restaurantId;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final String image;
  final bool isPopular;
  final String availability;

  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateFoodItemVariables.fromJson(Map<String, dynamic> json)
      : id = nativeFromJson<String>(json['id']),
        restaurantId = nativeFromJson<String>(json['restaurantId']),
        categoryId = nativeFromJson<String>(json['categoryId']),
        name = nativeFromJson<String>(json['name']),
        description = nativeFromJson<String>(json['description']),
        price = nativeFromJson<double>(json['price']),
        image = nativeFromJson<String>(json['image']),
        isPopular = nativeFromJson<bool>(json['isPopular']),
        availability = nativeFromJson<String>(json['availability']);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateFoodItemVariables otherTyped = other as CreateFoodItemVariables;
    return id == otherTyped.id &&
        restaurantId == otherTyped.restaurantId &&
        categoryId == otherTyped.categoryId &&
        name == otherTyped.name &&
        description == otherTyped.description &&
        price == otherTyped.price &&
        image == otherTyped.image &&
        isPopular == otherTyped.isPopular &&
        availability == otherTyped.availability;
  }

  @override
  int get hashCode => Object.hashAll([
        id.hashCode,
        restaurantId.hashCode,
        categoryId.hashCode,
        name.hashCode,
        description.hashCode,
        price.hashCode,
        image.hashCode,
        isPopular.hashCode,
        availability.hashCode,
      ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['restaurantId'] = nativeToJson<String>(restaurantId);
    json['categoryId'] = nativeToJson<String>(categoryId);
    json['name'] = nativeToJson<String>(name);
    json['description'] = nativeToJson<String>(description);
    json['price'] = nativeToJson<double>(price);
    json['image'] = nativeToJson<String>(image);
    json['isPopular'] = nativeToJson<bool>(isPopular);
    json['availability'] = nativeToJson<String>(availability);
    return json;
  }

  CreateFoodItemVariables({
    required this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.isPopular,
    required this.availability,
  });
}
