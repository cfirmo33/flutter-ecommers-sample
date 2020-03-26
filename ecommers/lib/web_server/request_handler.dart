import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http_server/http_server.dart';
import '../core/common/index.dart';
import '../extensions/string_extension.dart';

import 'data_access/user_data_access.dart';

import 'models/product.dart';
import 'models/user.dart';
import 'services/authorization_service.dart';
import 'services/data_provider.dart';

class RequestHandler {
  static final UserDataAccess _userDataAccess = UserDataAccess.instance;

  static String getMethod = 'GET';
  static String postMethod = 'GET';

  void process(HttpRequestBody body) {
    final path = body.request.uri.path.toString();

    switch (path) {
      case ApiDefines.login:
        _handleLoginRequest(body);
        break;
      case ApiDefines.auth:
        _handleAuthorizationRequest(body);
        break;
      case ApiDefines.products:
        _handleProductsRequest(body);
        break;
      case ApiDefines.productsLatest:
        _handleCategoriesRequest(body);
        break;
      case ApiDefines.categories:
        _handleCategoriesRequest(body);
        break;
      case ApiDefines.searchRecommended:
        _handleSearchRecommendedReq(body);
        break;
      case ApiDefines.searchRecentlyViewed:
        if (body.request.method == getMethod) {
          _handleSearchRecentlyViewedReq(body);
        } else if (body.request.method == postMethod) {
          _handleSearchRecentlyViewedPostReq(body);
        }
        break;
      default:
        _handleUnsupportedRequest(body);
    }
  }

  Future _handleLoginRequest(HttpRequestBody body) async {
    final userMap = body.body as Map<String, dynamic>;
    final user = User.fromJsonFactory(userMap);

    if (await _userDataAccess.isUserExists(user)) {
      body.request.response
        ..headers.contentType = ContentType.json
        ..write(AuthorizationService.signToken(userMap))
        ..close();

      return;
    }

    body.request.response
      ..statusCode = HttpStatus.unauthorized
      ..close();
  }

  Future _handleAuthorizationRequest(HttpRequestBody body) async {
    final userMap = body.body as Map<String, dynamic>;
    final user = User.fromJsonFactory(userMap);

    final validationModel = await _userDataAccess.isNewUserValid(user);

    if (validationModel.isValid) {
      await _userDataAccess.saveUser(userMap);

      body.request.response
        ..headers.contentType = ContentType.json
        ..write(AuthorizationService.signToken(userMap))
        ..close();

      return;
    }

    body.request.response
      ..statusCode = HttpStatus.unauthorized
      ..write(validationModel.error)
      ..close();
  }

  Future _handleProductsRequest(HttpRequestBody body) async {
    const int itemsPortion = 20;

    Iterable<Product> resultProducts = DataProvider.products;
    final queryParameters = body.request.uri.queryParameters;

    final category = queryParameters['category'];
    final subCategory = queryParameters['subCategory'];
    final rangeFrom = queryParameters['rangeFrom'];
    final rangeTo = queryParameters['rangeTo'];
    final searchQuery = queryParameters['searchQuery'];
    final sortType = queryParameters['sortType'];

    if (category.isNotNullOrEmpty) {
      resultProducts = resultProducts.where((p) => p.category == category);
    } else if (subCategory.isNotNullOrEmpty) {
      resultProducts = resultProducts.where(
          (p) => p.category == subCategory); //!  p.category to SubCategory
    } else if (rangeFrom.isNotNullOrEmpty && rangeTo.isNotNullOrEmpty) {
      resultProducts =
          resultProducts.skip(int.parse(rangeFrom)).take(int.parse(rangeTo));
    } else if (searchQuery.isNotNullOrEmpty) {
      resultProducts =
          resultProducts.where((p) => p.title.contains(searchQuery));
    }

    if (resultProducts.length > itemsPortion) {
      resultProducts = resultProducts.take(itemsPortion);
    }

    body.request.response
      ..headers.contentType = ContentType.json
      ..write(json.encode(resultProducts))
      ..close();
  }

  Future _handleSearchRecommendedReq(HttpRequestBody body) async {
    const recommendedCount =  5;
    final random =  Random();

    final resultProducts = DataProvider.products.skip(random.nextInt(5000)).take(recommendedCount);
    final productsJson = json.encode(resultProducts);

    body.request.response
      ..headers.contentType = ContentType.json
      ..write(productsJson)
      ..close();
  }

  Future _handleSearchRecentlyViewedReq(HttpRequestBody body) async {
    // final categoriesJson = json.encode(DataProvider.categories);

    // body.request.response
    //   ..headers.contentType = ContentType.json
    //   ..write(categoriesJson)
    //   ..close();
  }

  Future _handleSearchRecentlyViewedPostReq(HttpRequestBody body) async {
    // final categoriesJson = json.encode(DataProvider.categories);

    // body.request.response
    //   ..headers.contentType = ContentType.json
    //   ..write(categoriesJson)
    //   ..close();
  }

  Future _handleCategoriesRequest(HttpRequestBody body) async {
    final categoriesJson = json.encode(DataProvider.categories);

    body.request.response
      ..headers.contentType = ContentType.json
      ..write(categoriesJson)
      ..close();
  }

  Future _handleUnsupportedRequest(HttpRequestBody body) async {
    const String unsupported = 'Unsupported API';

    body.request.response
      ..headers.contentType = ContentType.text
      ..statusCode = HttpStatus.notImplemented
      ..write(unsupported)
      ..close();
  }
}
