import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

// Offer Model
class Offer {
  final String id;
  final String code;
  final String description;
  final String discountType;
  final num discountValue;
  final num maxDiscount;
  final num minOrderValue;
  final String discountDisplay;
  final Map<String, dynamic> usage;
  final Map<String, dynamic> validity;

  Offer({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.maxDiscount,
    required this.minOrderValue,
    required this.discountDisplay,
    required this.usage,
    required this.validity,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discountType'] ?? 'fixed',
      discountValue: json['discountValue'] ?? 0,
      maxDiscount: json['maxDiscount'] ?? 0,
      minOrderValue: json['minOrderValue'] ?? 0,
      discountDisplay: json['discountDisplay'] ?? '',
      usage: json['usage'] ?? {},
      validity: json['validity'] ?? {},
    );
  }
}

class OffersApiService {
  final Dio _dio;
  final String baseUrl;

  OffersApiService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  Future<List<Offer>> fetchAllOffers() async {
    try {
      final response = await _dio.get('$baseUrl/api/v1/offers');
      final list = (response.data['offers'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      return list.map(Offer.fromJson).toList();
    } catch (e) {
      print('Error fetching offers: $e');
      return [];
    }
  }

  Future<Offer?> fetchOfferById(String id) async {
    try {
      final response = await _dio.get('$baseUrl/api/v1/offers/$id');
      return Offer.fromJson(response.data['offer']);
    } catch (e) {
      print('Error fetching offer: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> validateCoupon(
    String code,
    double orderAmount,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/v1/offers/validate',
        data: {
          'code': code,
          'orderAmount': orderAmount,
        },
      );
      return response.data;
    } catch (e) {
      print('Error validating coupon: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> applyCoupon(
    String code,
    double orderAmount, {
    String? userId,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/v1/offers/apply',
        data: {
          'code': code,
          'orderAmount': orderAmount,
          if (userId != null) 'userId': userId,
        },
      );
      return response.data;
    } catch (e) {
      print('Error applying coupon: $e');
      rethrow;
    }
  }
}
