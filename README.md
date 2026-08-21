# fuertes_advmobprogAY2627

Advanced Mobile Programming (INF231) laboratory activities.

**Name:** Jorge Fuertes
**Section:** INF231

Flutter project: `fuertes_advmobprog/`

| Branch | Activity | Topic |
| --- | --- | --- |
| `lab_act1` | Lab Activity 1 | Ephemeral vs. App State |
| `lab_act2` | Lab Activity 2 | API |
| `lab_act3` | Lab Activity 3 | API Part II (Cart) |

---

## Lab Activity 1: discussion

**Ephemeral state** is data kept inside one widget with `setState`. In this
activity that is `_ephemeralCount` inside `_CounterScreenState`. Only that widget
can see it, and it is thrown away when the widget is rebuilt.

**App state** is data kept in a `ChangeNotifier` registered with
`ChangeNotifierProvider` above `MaterialApp`. Here that is `ThemeModel` for the
theme and `CounterModel` for the second counter. Because the providers sit above
the `Navigator`, pushing and popping screens does not destroy them, and any
screen can read them with `context.watch`.

The app shows the difference with one Increment button that raises both counters
at the same time. While the screen stays alive the two numbers match. Tapping
**Rebuild this screen** calls `Navigator.pushReplacement`, which throws away the
old `State` object, so the ephemeral counter goes back to 0 while the app state
counter keeps its value.

The theme is the second example. The switch is on a different screen, but
flipping it restyles the whole app because `themeMode` is driven by
`context.watch<ThemeModel>()`.

`setState` is the right choice for something only one widget cares about, like a
checkbox or a text field. Provider is for data that more than one screen needs or
that has to outlive the widget that made it, like the theme or a cart.

Screens: **Counter** (both counters plus a short explanation) and
**Theme Settings** (the dark/light switch).

---

## Lab Activity 2: discussion

Demi Mart lists products from the [dummyjson.com](https://dummyjson.com) API.

### How the model, services and screen work together

`constants.dart` reads `HOST` from `assets/.env`, loaded in `main()` before
`runApp`, so the URL is not hard coded.

`ProductService` does the HTTP work. `getAllProducts()` calls
`GET $host/products`, checks the status code, decodes the JSON, takes the
`products` array and maps each entry through `Product.fromJson`. It returns a
`List<Product>`, so nothing above it deals with JSON.

`Product.fromJson` turns one map into typed fields, including the nested
`ProductDimensions`, `ProductReview` and `ProductMeta`. Numbers are read as `num`
first because the API sends `4` for a whole number and `9.99` for a decimal, and
every field has a default so a missing key does not crash the app.

`ProductScreen` starts the request in `initState` and hands the `Future` to a
`FutureBuilder`, which rebuilds as the request finishes. That covers all the
states in one place: a spinner while loading, an error message with a Retry
button if it fails, a message if nothing matched, and the grid on success. The
screen never touches `http` or `jsonDecode`.

### The design pattern

Lab Activity 1 was a single `main.dart`. This activity splits the code by
responsibility:

```
lib/
├── models/      Product and its nested classes
├── providers/   ThemeProvider (app state, from Lab Activity 1)
├── screens/     home, product, product_details, settings
├── services/    ProductService, all the API calls
├── widgets/     CustomText
├── constants.dart
└── main.dart
```

Each file has one reason to change: a new API field is a `models/` edit, a new
endpoint is a `services/` edit, and neither touches the UI. The model and the
provider are plain Dart, so they can be tested without the network.

Two packages support the UI. `flutter_screenutil` sets the design size the layout
was made for (412x715) so sizes like `16.sp` scale on other phones. `provider`
keeps the theme above `MaterialApp` so it applies to every screen.

### Enhancements

**1. Search bar** above the product list. Typing waits 450 ms before sending, so
fast typing makes one request instead of one per letter, and `searchProducts()`
calls `/products/search?q=` so the API does the filtering.

**2. Details page** when a card is tapped. The product is passed to the screen
directly, so it needs no second API call. It shows an image carousel, the
discounted price against the original, the star rating, availability, the
specifications from the nested objects, tags, and the reviews.

**3. Settings page** with the dark/light switch, bound to `ThemeProvider`.

---

## Lab Activity 3: discussion

The Cart tab shows a cart from the same [dummyjson.com](https://dummyjson.com)
API, and its items open the product page the Shop grid already uses.

### How the model, service and screen work together

`Cart.fromJson` takes one cart object and builds typed fields out of it. The
`products` array is mapped through `CartProduct.fromJson`, so a `Cart` holds a
`List<CartProduct>` instead of a list of maps. As in `Product`, numbers are read
as `num` before `toDouble()`, because the API sends `4` for a whole quantity and
`1145.17` for a total, and every field has a default so a missing key cannot
crash the screen. Both classes also have `toJson()`, which is what makes the
cart a value the app can hand back to the API.

`CartService` is the only place that touches `http` and `jsonDecode`.
`getAllCarts()` calls `GET $host/carts`, checks the status code, and maps the
`carts` array through `Cart.fromJson`. `getCartByUserId()` and `addToCart()`
follow the same shape. Every method returns a `Cart` or a `List<Cart>`, so the
screens never see JSON.

`CartScreen` starts the request in `initState` and hands the `Future` to a
`FutureBuilder`, the same way `ProductScreen` does, so loading, error with a
Retry button, empty and loaded are all handled in one place. Once the response
arrives the items are copied into rows the screen owns, so the `+` and `-`
buttons can change a quantity and recompute the subtotal without asking the API
again. The model stays immutable; only the screen's copy changes.

### Reaching the same detail screen

A `CartProduct` carries the id, title, price, quantity and thumbnail, but not
the description, images or reviews the product page shows. So a cart row cannot
build that page from what it already has.

Rather than write a second details screen, `DetailScreen` now takes either a
`Product` or a `productId`:

```dart
const DetailScreen({super.key, this.product, this.productId})
```

The Shop grid already holds the whole product, so it passes `product` and the
page needs no request. A cart row only knows the id, so it passes `productId`
and the screen fetches it with `ProductService.getProductById()` inside a
`FutureBuilder`. Both paths end in the same `_buildDetails()` method, so there
is one layout to maintain and one place to change it.

### Using getById at the Cart endpoint

The cart endpoint has two ways to fetch one record, and they are not the same:

- `GET /carts/{id}` takes a **cart** id and returns a single cart object.
- `GET /carts/user/{userId}` takes a **user** id and returns
  `{"carts": [...], "total": 1, "skip": 0, "limit": 1}` — an object with a list
  inside it, even for one user.

The activity asks for one user's cart, so `getCartByUserId()` uses the second
one, reads `data['carts']`, and returns `cartsJson.first`. A user with no cart
yet comes back as an empty list rather than an error, which is why the method
returns `Cart?` and the screen shows an empty-cart message instead of the error
state. The user id is `defaultUserId` in `constants.dart` for now; Lab Activity 4
replaces it with the id of whoever signed in.

`POST /carts/add` is the other direction. It takes a `userId` and a list of
`{id, quantity}` products and returns the resulting cart, which is what the
**Add to Cart** button sends. Worth knowing: dummyjson simulates this endpoint.
The response is real and the totals it returns are correct, but nothing is
stored, so fetching the cart again does not show the added item.

### The updated design pattern

Lab Activity 2 had one model and one service. This activity adds a second pair
beside them instead of widening the first:

```
lib/
├── models/      Product, Cart
├── providers/   ThemeProvider
├── screens/     home, product, cart, detail, settings
├── services/    ProductService, CartService
├── widgets/     CustomText
├── constants.dart
└── main.dart
```

The folders did not change, only what is in them, which is the point of laying
the project out this way in the first place. A new endpoint is a new method in
`services/`, a new response shape is a new class in `models/`, and neither one
touches the screens. `product_details_screen.dart` is now `detail_screen.dart`,
since it is no longer reached only from the product grid.

### Enhancements

**1. Cart screen** rendering the cart endpoint. Rows show the thumbnail, price,
discount and line total, and tapping one opens `DetailScreen` by id, so the cart
and the grid share a single product page.

**2. Chat moved to a FloatingActionButton.** The bottom bar is now Shop, Cart and
Profile. The button is built as `null` when `_selectedIndex == 1`, so it
disappears on the cart screen instead of covering the Confirm Order button.

**3. Cart by user id.** `getCartByUserId()` calls `/carts/user/{userId}` so only
one cart is rendered, and `addToCart()` posts a product and quantity to
`/carts/add` and reports the total that comes back.
