# fuertes_advmobprogAY2627

Advanced Mobile Programming (INF231) laboratory activities.

**Name:** Jorge Fuertes
**Section:** INF231

Flutter project: `fuertes_advmobprog/`

| Branch | Activity | Topic |
| --- | --- | --- |
| `lab_act1` | Lab Activity 1 | Ephemeral vs. App State |
| `lab_act2` | Lab Activity 2 | API |

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
