import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'data/data.dart';
import 'model/product_model/product_model.dart';
import 'package:collection/collection.dart';

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..post('/login', login)
  ..get('/products', getProducts)
  ..post('/products', addProducts)
  ..post('/cart', addToCart)
  ..get('/cart', getCart);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}

Future<Response> login(Request req) async {
  final data = jsonDecode(await req.readAsString());
  if (data['password'] != null) {
    return Response.ok(
        jsonEncode({
          "success": true,
        }),
        headers: {'Content-type': 'application/json'});
  }
  return Response.badRequest(
      body: jsonEncode({"error": "bad request"}),
      headers: {'Content-type': 'application/json'});
}

Future<Response> addProducts(Request req) async {
  final data = jsonDecode(await req.readAsString());
  final product = ProductModel.fromJson(data);
  final doesContain = products.firstWhereOrNull(
    (element) => element.productId == product.productId,
  );
  if (doesContain == null) {
    products.add(product);
    return Response.ok(jsonEncode({"success": true}),
        headers: {'Content-type': 'application/json'});
  }
  return Response.badRequest();
}

Future<Response> addToCart(Request req) async {
  final data = jsonDecode(await req.readAsString());
  final productId = data['productId'];
  final product = products.firstWhereOrNull(
    (element) => element.productId == productId,
  );
  if (product != null) {
    globalCart.add(product);
    return Response.ok(jsonEncode({"success": true}),
        headers: {'Content-type': 'application/json'});
  }
  return Response.badRequest();
}

Response getProducts(Request req) {
  return Response.ok(jsonEncode({"products": products}),
      headers: {'Content-type': 'application/json'});
}

Response getCart(Request req) {
  return Response.ok(jsonEncode({"cartItems": globalCart}),
      headers: {'Content-type': 'application/json'});
}
