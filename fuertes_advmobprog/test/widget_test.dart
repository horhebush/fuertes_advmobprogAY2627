import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fuertes_advmobprog/constants.dart';
import 'package:fuertes_advmobprog/models/cart.dart';
import 'package:fuertes_advmobprog/models/message.dart';
import 'package:fuertes_advmobprog/services/chat_service.dart';
import 'package:fuertes_advmobprog/models/product.dart';
import 'package:fuertes_advmobprog/models/user.dart';
import 'package:fuertes_advmobprog/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fuertes_advmobprog/providers/theme_provider.dart';
import 'package:fuertes_advmobprog/utils/login_type.dart';
import 'package:fuertes_advmobprog/utils/validators.dart';

// A sample response from the API.
final sampleJson = {
  'id': 1,
  'title': 'Essence Mascara Lash Princess',
  'description': 'A popular mascara known for its volumizing effect.',
  'category': 'beauty',
  'price': 9.99,
  'discountPercentage': 10.48,
  'rating': 2.56,
  'stock': 99,
  'tags': ['beauty', 'mascara'],
  'brand': 'Essence',
  'sku': 'BEA-ESS-ESS-001',
  'weight': 4,
  'dimensions': {'width': 15.14, 'height': 13.08, 'depth': 22.99},
  'warrantyInformation': '1 week warranty',
  'shippingInformation': 'Ships in 3-5 business days',
  'availabilityStatus': 'In Stock',
  'reviews': [
    {
      'rating': 3,
      'comment': 'Would not recommend!',
      'date': '2025-04-30T09:41:02.053Z',
      'reviewerName': 'Eleanor Collins',
      'reviewerEmail': 'eleanor.collins@x.dummyjson.com',
    },
  ],
  'returnPolicy': '30 days return policy',
  'minimumOrderQuantity': 24,
  'meta': {
    'createdAt': '2025-04-30T09:41:02.053Z',
    'updatedAt': '2025-04-30T09:41:02.053Z',
    'barcode': '9164035109868',
    'qrCode': 'https://cdn.dummyjson.com/public/qr-code.png',
  },
  'images': ['https://cdn.dummyjson.com/product-images/1/1.webp'],
  'thumbnail': 'https://cdn.dummyjson.com/product-images/1/thumbnail.webp',
};

// A sample cart response from the API.
final sampleCartJson = {
  'id': 5,
  'products': [
    {
      'id': 161,
      'title': 'Samsung Galaxy Tab White',
      'price': 349.99,
      'quantity': 4,
      'total': 1399.96,
      'discountPercentage': 18.2,
      'discountedTotal': 1145.17,
      'thumbnail': 'https://cdn.dummyjson.com/product-images/161/thumbnail.webp',
    },
  ],
  'total': 1467.88,
  'discountedTotal': 1205.8,
  'userId': 5,
  'totalProducts': 3,
  'totalQuantity': 12,
};

// A sample login response from the API.
final sampleUserJson = {
  'accessToken': 'header.payload.signature',
  'refreshToken': 'refresh.payload.signature',
  'id': 1,
  'username': 'emilys',
  'email': 'emily.johnson@x.dummyjson.com',
  'firstName': 'Emily',
  'lastName': 'Johnson',
  'gender': 'female',
  'image': 'https://dummyjson.com/icon/emilys/128',
};

void main() {
  test('Product.fromJson reads the response', () {
    final p = Product.fromJson(sampleJson);

    expect(p.title, 'Essence Mascara Lash Princess');
    expect(p.price, 9.99);
    expect(p.stock, 99);
    expect(p.dimensions.width, 15.14);
    expect(p.reviews.first.reviewerName, 'Eleanor Collins');
    expect(p.weight, 4.0);
  });

  test('Product.fromJson uses defaults when fields are missing', () {
    final p = Product.fromJson({});

    expect(p.id, 0);
    expect(p.title, '');
    expect(p.price, 0.0);
    expect(p.reviews, isEmpty);
  });

  test('discountedPrice takes the discount off the price', () {
    final p = Product.fromJson(sampleJson);
    expect(p.discountedPrice, closeTo(8.94, 0.01));
  });

  test('Cart.fromJson reads the response', () {
    final c = Cart.fromJson(sampleCartJson);

    expect(c.id, 5);
    expect(c.userId, 5);
    expect(c.total, 1467.88);
    expect(c.discountedTotal, 1205.8);
    expect(c.totalQuantity, 12);
    expect(c.products, hasLength(1));
    expect(c.products.first.title, 'Samsung Galaxy Tab White');
  });

  test('Cart.fromJson uses defaults when fields are missing', () {
    final c = Cart.fromJson({});

    expect(c.id, 0);
    expect(c.userId, 0);
    expect(c.total, 0.0);
    expect(c.products, isEmpty);
  });

  test('CartProduct.fromJson reads the line item', () {
    final line = CartProduct.fromJson(
      (sampleCartJson['products'] as List).first as Map<String, dynamic>,
    );

    expect(line.id, 161);
    expect(line.quantity, 4);
    expect(line.price, 349.99);
    expect(line.discountedTotal, 1145.17);
  });

  test('Cart.toJson round trips', () {
    final c = Cart.fromJson(sampleCartJson);
    final again = Cart.fromJson(c.toJson());

    expect(again.id, c.id);
    expect(again.discountedTotal, c.discountedTotal);
    expect(again.products.first.title, c.products.first.title);
  });

  test('User.fromJson reads the login response', () {
    final u = User.fromJson(sampleUserJson);

    expect(u.id, 1);
    expect(u.username, 'emilys');
    expect(u.fullName, 'Emily Johnson');
    expect(u.email, 'emily.johnson@x.dummyjson.com');
    expect(u.accessToken, 'header.payload.signature');
    expect(u.refreshToken, 'refresh.payload.signature');
  });

  test('User.fromJson uses defaults when fields are missing', () {
    final u = User.fromJson({});

    expect(u.id, 0);
    expect(u.username, '');
    expect(u.fullName, '');
    expect(u.accessToken, '');
  });

  test('User.fromJson falls back to the generic token key', () {
    final u = User.fromJson({'id': 3, 'token': 'legacy.token'});

    expect(u.accessToken, 'legacy.token');
  });

  test('saveUserData then getUser keeps every field', () async {
    SharedPreferences.setMockInitialValues({});
    final service = UserService();

    await service.saveUserData(sampleUserJson);
    final u = await service.getUser();

    expect(u.id, 1);
    expect(u.username, 'emilys');
    // The handout saves this under 'lasName' but reads 'lastName', which
    // loses the surname. This asserts the key matches on both sides.
    expect(u.lastName, 'Johnson');
    expect(u.fullName, 'Emily Johnson');
    expect(u.gender, 'female');
    expect(await service.isLoggedIn(), isTrue);
  });

  test('logout clears the saved user', () async {
    SharedPreferences.setMockInitialValues({});
    final service = UserService();

    await service.saveUserData(sampleUserJson);
    expect(await service.isLoggedIn(), isTrue);

    await service.logout();
    expect(await service.isLoggedIn(), isFalse);
    expect((await service.getUser()).username, '');
  });

  test('ThemeProvider toggles between light and dark', () {
    final provider = ThemeProvider();
    expect(provider.isDark, isFalse);

    provider.toggleTheme();
    expect(provider.isDark, isTrue);
    expect(provider.darkTheme.brightness, Brightness.dark);
  });

  // ENHANCEMENT 2: the fields a Firebase account adds on top of the API one.
  test('User.fromJson reads a Firestore profile', () {
    final u = User.fromJson({
      'uid': 'abc123',
      'username': 'jorge',
      'email': 'jorge@example.com',
      'firstName': 'Jorge',
      'lastName': 'Fuertes',
      'age': 21,
      'contactNo': '09171234567',
    });

    expect(u.uid, 'abc123');
    expect(u.age, 21);
    expect(u.contactNo, '09171234567');
    expect(u.fullName, 'Jorge Fuertes');
    // A Firebase account has no dummyJSON id or avatar.
    expect(u.id, 0);
    expect(u.image, '');
  });

  test('toFirestore keeps only the profile fields', () {
    final u = User.fromJson(sampleUserJson);

    expect(u.toFirestore().keys, isNot(contains('accessToken')));
    expect(u.toFirestore()['username'], 'emilys');
  });

  test('login type round trips and defaults to dummyJSON', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await readLoginType(), LoginType.dummyJson);

    await saveLoginType(LoginType.firebase);
    expect(await readLoginType(), LoginType.firebase);

    await saveLoginType(LoginType.dummyJson);
    expect(await readLoginType(), LoginType.dummyJson);
  });

  test('email validator accepts an address and rejects rubbish', () {
    expect(validateEmail('jorge@example.com'), isNull);
    expect(validateEmail(''), isNotNull);
    expect(validateEmail('jorge@'), isNotNull);
    expect(validateEmail('jorge.example.com'), isNotNull);
  });

  test('age validator holds the range', () {
    expect(validateAge('21'), isNull);
    expect(validateAge('12'), isNotNull);
    expect(validateAge('121'), isNotNull);
    expect(validateAge('abc'), isNotNull);
  });

  test('contact number validator wants eleven digits', () {
    expect(validateContactNo('09171234567'), isNull);
    expect(validateContactNo('0917123456'), isNotNull);
    expect(validateContactNo('0917-123-4567'), isNotNull);
  });

  test('password validator wants length, a letter and a number', () {
    expect(validatePassword('demimart1'), isNull);
    expect(validatePassword('short1'), isNotNull);
    expect(validatePassword('allletters'), isNotNull);
    expect(validatePassword('12345678'), isNotNull);
  });

  test('confirm password validator compares the two boxes', () {
    expect(validateConfirmPassword('demimart1', 'demimart1'), isNull);
    expect(validateConfirmPassword('demimart2', 'demimart1'), isNotNull);
  });

  test('required validator names the field it is missing', () {
    expect(validateRequired('jorge', 'username'), isNull);
    expect(validateRequired('   ', 'username'), contains('username'));
  });

  // A Firebase account has no dummyJSON id, and /carts/user/0 answers 404,
  // so the cart tab has to fall back instead of asking for user 0.
  test('a Firebase user has no dummyJSON id to hang a cart on', () {
    final firebaseUser = User.fromJson({
      'uid': 'abc123',
      'username': 'jorge',
      'email': 'jorge@example.com',
    });
    expect(firebaseUser.id, 0);

    final cartOwner = firebaseUser.id == 0 ? defaultUserId : firebaseUser.id;
    expect(cartOwner, defaultUserId);

    final apiUser = User.fromJson(sampleUserJson);
    expect(apiUser.id == 0 ? defaultUserId : apiUser.id, 1);
  });

  // The chat list reads uid back off the profile document, so it has to be
  // written into it and not only used as the document id.
  test('toFirestore carries the uid the chat list needs', () {
    final u = User.fromJson({'uid': 'abc123', 'username': 'jorge'});
    expect(u.toFirestore()['uid'], 'abc123');
  });

  test('a chat room id is the same for both people in it', () {
    final service = ChatService();

    expect(service.chatRoomId('aaa', 'bbb'), 'aaa_bbb');
    // Sorting is what makes it symmetric.
    expect(
      service.chatRoomId('bbb', 'aaa'),
      service.chatRoomId('aaa', 'bbb'),
    );
    // Two different pairs never collide.
    expect(
      service.chatRoomId('aaa', 'ccc'),
      isNot(service.chatRoomId('aaa', 'bbb')),
    );
  });

  test('MessageModel round trips through the Firestore map', () {
    final stamp = Timestamp.fromDate(DateTime.utc(2026, 9, 25, 8, 30));
    final message = MessageModel(
      senderId: 'aaa',
      senderEmail: 'jorge@example.com',
      receiverId: 'bbb',
      message: 'hello there',
      timestamp: stamp,
    );

    final again = MessageModel.fromMap(message.toMap());

    expect(again.senderId, 'aaa');
    expect(again.receiverId, 'bbb');
    expect(again.message, 'hello there');
    expect(again.timestamp, stamp);
  });

  test('MessageModel survives a document with missing fields', () {
    final m = MessageModel.fromMap({});

    expect(m.senderId, '');
    expect(m.message, '');
    expect(m.timestamp, isA<Timestamp>());
  });
}
