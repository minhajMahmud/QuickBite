library dataconnect_generated;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'create_food_item.dart';

part 'update_order_status.dart';

part 'list_restaurants.dart';

part 'list_food_items_by_restaurant.dart';

class ExampleConnector {
  CreateFoodItemVariablesBuilder createFoodItem({
    required String id,
    required String restaurantId,
    required String categoryId,
    required String name,
    required String description,
    required double price,
    required String image,
    required bool isPopular,
    required String availability,
  }) {
    return CreateFoodItemVariablesBuilder(
      dataConnect,
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
  }

  UpdateOrderStatusVariablesBuilder updateOrderStatus({
    required String orderId,
    required String orderStatus,
  }) {
    return UpdateOrderStatusVariablesBuilder(
      dataConnect,
      orderId: orderId,
      orderStatus: orderStatus,
    );
  }

  ListRestaurantsVariablesBuilder listRestaurants() {
    return ListRestaurantsVariablesBuilder(
      dataConnect,
    );
  }

  ListFoodItemsByRestaurantVariablesBuilder listFoodItemsByRestaurant({
    required String restaurantId,
  }) {
    return ListFoodItemsByRestaurantVariablesBuilder(
      dataConnect,
      restaurantId: restaurantId,
    );
  }

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-south1',
    'example',
    'flutter',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    final app = Firebase.app();
    return ExampleConnector(
      // ignore: invalid_use_of_visible_for_testing_member
      dataConnect: FirebaseDataConnect(
        app: app,
        auth: FirebaseAuth.instanceFor(app: app),
        appCheck: null,
        connectorConfig: connectorConfig,
        sdkType: CallerSDKType.generated,
      ),
    );
  }

  FirebaseDataConnect dataConnect;
}
