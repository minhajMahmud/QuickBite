import '../models/models.dart';
import '../models/user_model.dart';

/// Mock Data Service - provides static data for the application
class MockDataService {
  static const List<Category> categories = [
    Category(id: '1', name: 'Burgers', icon: '🍔'),
    Category(id: '2', name: 'Pizza', icon: '🍕'),
    Category(id: '3', name: 'Sushi', icon: '🍣'),
    Category(id: '4', name: 'Salads', icon: '🥗'),
    Category(id: '5', name: 'Desserts', icon: '🍰'),
    Category(id: '6', name: 'Coffee', icon: '☕'),
    Category(id: '7', name: 'Pasta', icon: '🍝'),
    Category(id: '8', name: 'Tacos', icon: '🌮'),
  ];

  static const List<Restaurant> restaurants = [
    Restaurant(
      id: '1',
      name: 'The Golden Grill',
      image:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600&h=400&fit=crop',
      cuisine: 'American • Burgers',
      rating: 4.8,
      deliveryTime: '15-25 min',
      deliveryFee: 'Free',
      popular: true,
      priceRange: '\$\$',
    ),
    Restaurant(
      id: '2',
      name: 'Sakura House',
      image:
          'https://images.unsplash.com/photo-1579027989536-b7b1f875659b?w=600&h=400&fit=crop',
      cuisine: 'Japanese • Sushi',
      rating: 4.9,
      deliveryTime: '20-30 min',
      deliveryFee: '\$2.99',
      popular: true,
      priceRange: '\$\$\$',
    ),
    Restaurant(
      id: '3',
      name: 'Bella Napoli',
      image:
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600&h=400&fit=crop',
      cuisine: 'Italian • Pizza',
      rating: 4.7,
      deliveryTime: '25-35 min',
      deliveryFee: '\$1.99',
      popular: false,
      priceRange: '\$\$',
    ),
    Restaurant(
      id: '4',
      name: 'Green Garden',
      image:
          'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?w=600&h=400&fit=crop',
      cuisine: 'Healthy • Salads',
      rating: 4.6,
      deliveryTime: '15-20 min',
      deliveryFee: 'Free',
      popular: false,
      priceRange: '\$',
    ),
    Restaurant(
      id: '5',
      name: 'Spice Route',
      image:
          'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=600&h=400&fit=crop',
      cuisine: 'Indian • Curry',
      rating: 4.8,
      deliveryTime: '30-40 min',
      deliveryFee: '\$2.49',
      popular: true,
      priceRange: '\$\$',
    ),
    Restaurant(
      id: '6',
      name: 'Thai Orchid',
      image:
          'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=600&h=400&fit=crop',
      cuisine: 'Thai • Noodles',
      rating: 4.8,
      deliveryTime: '30-40 min',
      deliveryFee: '\$2.49',
      popular: true,
      priceRange: '\$\$',
    ),
  ];

  static const List<FoodItem> foodItems = [
    // The Golden Grill
    FoodItem(
      id: 'f1',
      restaurantId: '1',
      name: 'Classic Smash Burger',
      description:
          'Double patty, aged cheddar, caramelized onions, special sauce',
      price: 14.99,
      image:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&h=300&fit=crop',
      category: 'Burgers',
      popular: true,
    ),
    FoodItem(
      id: 'f2',
      restaurantId: '1',
      name: 'Truffle Fries',
      description: 'Hand-cut fries, truffle oil, parmesan, herbs',
      price: 8.99,
      image:
          'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400&h=300&fit=crop',
      category: 'Sides',
      popular: true,
    ),
    // Sakura House
    FoodItem(
      id: 'f6',
      restaurantId: '2',
      name: 'Dragon Roll',
      description: 'Shrimp tempura, avocado, eel, special sauce',
      price: 18.99,
      image:
          'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=300&fit=crop',
      category: 'Sushi',
      popular: true,
    ),
    FoodItem(
      id: 'f7',
      restaurantId: '2',
      name: 'Salmon Sashimi',
      description: 'Fresh Atlantic salmon, 8 pieces',
      price: 16.99,
      image:
          'https://images.unsplash.com/photo-1534256958597-7fe685cbd745?w=400&h=300&fit=crop',
      category: 'Sushi',
      popular: true,
    ),
    // Bella Napoli
    FoodItem(
      id: 'f11',
      restaurantId: '3',
      name: 'Margherita Pizza',
      description: 'San Marzano tomatoes, fresh mozzarella, basil',
      price: 13.99,
      image:
          'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400&h=300&fit=crop',
      category: 'Pizza',
      popular: true,
    ),
    FoodItem(
      id: 'f12',
      restaurantId: '3',
      name: 'Truffle Pasta',
      description: 'Fresh tagliatelle, black truffle, parmesan cream',
      price: 19.99,
      image:
          'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=400&h=300&fit=crop',
      category: 'Pasta',
      popular: true,
    ),
  ];

  static List<Order> generateMockOrders() {
    return [
      const Order(
        id: 'ord-0001',
        userId: 'u1',
        userName: 'Emma Wilson',
        restaurant: 'The Golden Grill',
        items: ['Classic Burger', 'Truffle Fries'],
        total: 34.99,
        status: 'delivered',
        date: '2026-02-15',
      ),
      const Order(
        id: 'ord-0002',
        userId: 'u2',
        userName: 'Liam Chen',
        restaurant: 'Sakura House',
        items: ['Dragon Roll', 'Miso Ramen'],
        total: 44.98,
        status: 'on_the_way',
        date: '2026-02-16',
      ),
      const Order(
        id: 'ord-0003',
        userId: 'u3',
        userName: 'Sophia Patel',
        restaurant: 'Bella Napoli',
        items: ['Margherita Pizza', 'Tiramisu'],
        total: 29.99,
        status: 'preparing',
        date: '2026-02-16',
      ),
    ];
  }

  static List<User> generateMockUsers() {
    final names = [
      'Emma Wilson',
      'Liam Chen',
      'Sophia Patel',
      'Noah Kim',
      'Olivia Martinez',
      'James Brown',
      'Ava Johnson',
      'Lucas Davis',
      'Mia Garcia',
      'Ethan Lee',
    ];
    return List.generate(
      10,
      (index) => User(
        id: 'u${index + 1}',
        name: names[index],
        email: 'user${index + 1}@quickbite.com',
        avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=${index}',
        status: index % 5 == 0 ? 'inactive' : 'active',
        orders: 10 + (index * 5),
        spent: 100 + (index * 50),
        joinedAt: '2025-${(index % 12) + 1}-01',
      ),
    );
  }

  static List<DeliveryAgent> generateMockDeliveryAgents() {
    return [
      const DeliveryAgent(
        id: 'd1',
        name: 'Mike Reynolds',
        avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=mike',
        rating: 4.9,
        deliveries: 2340,
        status: 'delivering',
      ),
      const DeliveryAgent(
        id: 'd2',
        name: 'Sarah Kim',
        avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=sarah',
        rating: 4.8,
        deliveries: 1890,
        status: 'online',
      ),
      const DeliveryAgent(
        id: 'd3',
        name: 'Carlos Mendez',
        avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=carlos',
        rating: 4.7,
        deliveries: 1560,
        status: 'delivering',
      ),
    ];
  }

  static KPIData getMockUserKPI() {
    return const KPIData(
      totalOrders: 24,
      totalSpent: 856.50,
      loyaltyPoints: 2540,
      savedAddresses: 3,
    );
  }

  static List<MonthlyRevenue> getMockMonthlyRevenue() {
    return [
      const MonthlyRevenue(
        month: 'Mar',
        revenue: 42000,
        orders: 1200,
        users: 320,
      ),
      const MonthlyRevenue(
        month: 'Apr',
        revenue: 48000,
        orders: 1380,
        users: 410,
      ),
      const MonthlyRevenue(
        month: 'May',
        revenue: 55000,
        orders: 1520,
        users: 480,
      ),
      const MonthlyRevenue(
        month: 'Jun',
        revenue: 61000,
        orders: 1690,
        users: 560,
      ),
      const MonthlyRevenue(
        month: 'Jul',
        revenue: 58000,
        orders: 1610,
        users: 620,
      ),
      const MonthlyRevenue(
        month: 'Aug',
        revenue: 67000,
        orders: 1840,
        users: 710,
      ),
    ];
  }
}
