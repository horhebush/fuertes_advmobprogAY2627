# fuertes_advmobprogAY2627

Advanced Mobile Programming (INF231) laboratory activities.

**Name:** Jorge Fuertes
**Section:** INF231
**School Year:** AY 2026-2027

Flutter project: [`fuertes_advmobprog/`](fuertes_advmobprog/)

| Branch | Activity | Topic |
| --- | --- | --- |
| `lab_act1` | Lab Activity 1 | Ephemeral vs. App State |
| `lab_act2` | Lab Activity 2 | API |

---

## Lab Activity 1: discussion

**Topic: Ephemeral vs. App State**

### The difference between `setState` and `Provider`

Flutter splits state into two kinds, and the difference is really about *where the
data lives* rather than what the data is.

**Ephemeral (local) state** lives inside the `State` object of a single
`StatefulWidget`. In this activity the ephemeral counter is the `_ephemeralCount`
field inside `_CounterScreenState`. Calling `setState()` mutates that field and
marks only that one widget as dirty, so Flutter re-runs just that widget's
`build()` method. This is cheap and simple, but the value is completely private:
no other screen can read it, and the moment the `State` object is disposed the
value is gone forever.

**App state** lives above the widget tree in a `ChangeNotifier` that is registered
with a `ChangeNotifierProvider`. In this activity there are two of them,
`ThemeProvider` and `CounterProvider`, both registered in `main()` inside a
`MultiProvider` that wraps `MaterialApp`. Because they sit *above* the
`Navigator`, pushing and popping routes never destroys them. Any widget can reach
them with `context.watch<T>()` (subscribe and rebuild on change) or
`context.read<T>()` (one-off read without subscribing). When the data changes,
`notifyListeners()` tells every subscribed widget to rebuild — even widgets on
other screens.

### How the app proves it

Both counters are incremented by the **same single button**, in the same callback:

```dart
onPressed: () {
  _incrementEphemeral();       // ephemeral, via setState
  counterProvider.increment(); // app state, via ChangeNotifier
},
```

While the counter screen stays alive the two numbers are always identical. Tapping
**Rebuild this screen** calls `Navigator.pushReplacement` with a fresh
`CounterScreen`, which disposes the old `State` object. At that moment the numbers
diverge: the ephemeral counter is back to `0` because its `State` was destroyed,
while the app-state counter still shows its accumulated value because it never
lived in the widget at all.

The theme is the second demonstration. The dark/light switch lives on a *different
screen* (`SettingsScreen`), yet flipping it restyles the entire app immediately,
because `MaterialApp`'s `themeMode` is driven by `context.watch<ThemeProvider>()`.
The settings screen also displays the app-state counter, showing the same value
being read from a completely separate route.

### When to use which

Use `setState` for things only one widget cares about — whether a checkbox is
ticked, the current page of a `PageView`, the text in a form field, an animation
progress value. Reaching for Provider here just adds boilerplate.

Use Provider (or another app-state solution) once two or more widgets need the
same data, or when the data must outlive the widget that created it — the signed-in
user, a shopping cart, the theme preference, cached API results. The rule of thumb
is: if losing the value on navigation would be a bug, it is app state.

### Screens

1. **Counter** — two cards side by side (ephemeral and app state), one increment
   button that raises both, per-card reset buttons, and a "Rebuild this screen"
   button that demonstrates the difference.
2. **Theme Settings** — the dark/light `SwitchListTile` backed by `ThemeProvider`,
   plus the app-state counter read from this second screen.

---

## Lab Activity 2: discussion

**Topic: API — Demi Mart**

A storefront that lists products fetched from the
[dummyjson.com](https://dummyjson.com) REST API.

### How the model, service and screen interact to render the API endpoint

The request travels through four layers, and each one only knows about the layer
directly beneath it:

**1. `constants.dart` — where the endpoint comes from.**
`host` is read from `assets/.env` (`HOST=https://dummyjson.com`), loaded by
`dotenv.load()` in `main()` before `runApp`. The URL is never hard-coded in a
Dart file, so the API can be repointed without recompiling logic.

**2. `services/product_service.dart` — the only layer that speaks HTTP.**
`getAllProducts()` issues `GET $host/products`, checks `statusCode == 200`,
`jsonDecode`s the body, pulls the `products` array out of the response envelope,
and maps each entry through `Product.fromJson`. A non-200 response throws. What
it returns is a `List<Product>` — no `Map`, no JSON, no `http` types leak upward.

**3. `models/product.dart` — the shape of the data.**
`Product.fromJson` converts one untyped `Map<String, dynamic>` into typed Dart
fields, including the nested `ProductDimensions`, `ProductReview` and
`ProductMeta` objects. Two details matter here:

- Numbers are read `as num?` then `.toDouble()`. The API sends `"weight": 4` for
  a whole number and `"price": 9.99` for a fraction; casting straight to `double`
  would crash on the first.
- Every field has a `?? fallback`, so a missing or renamed key degrades to a safe
  default instead of throwing mid-build.

**4. `screens/product_screen.dart` — where it becomes pixels.**
`initState` kicks off the request and stores the `Future` in a field. A
`FutureBuilder` subscribes to it and rebuilds as the request moves through its
states, which is why all four UI states live in one place:

| `snapshot` state | What the user sees |
| --- | --- |
| `ConnectionState.waiting` | `CircularProgressIndicator` |
| `hasError` | Message + **Retry** button |
| data, but empty | "No products match …" |
| data | `GridView` of product cards |

The screen never touches `http` or `jsonDecode`. It asks the service for
products, receives typed objects, and renders them — so the networking could be
swapped for a cache or a mock without editing a single widget.

### The new design pattern

Lab Activity 1 was a single `main.dart`. This activity introduces a **layered
(separation-of-concerns) architecture**, one folder per responsibility:

```
lib/
├── models/      Product, ProductDimensions, ProductReview, ProductMeta
├── providers/   ThemeProvider  (app state, carried over from Lab Activity 1)
├── screens/     home, product, product_details, settings
├── services/    ProductService  (all HTTP lives here)
├── widgets/     CustomText  (shared presentation)
├── constants.dart
└── main.dart
```

What this buys:

- **One reason to change per file.** A new API field is a `models/` edit. A
  changed endpoint is a `services/` edit. Neither touches the UI.
- **Testability.** The model and provider are plain Dart with no Flutter or
  network dependency, so they are unit-testable directly — `test/widget_test.dart`
  covers `Product.fromJson` (including the int-vs-double case and an empty
  payload) and `ThemeProvider` without ever hitting the network.
- **Consistency.** All copy goes through `CustomText`, so the Poppins family and
  sizing are applied in one place rather than repeated per `Text` widget.

Two supporting packages shape the UI layer:

- **`flutter_screenutil`** — `ScreenUtilInit` declares the design canvas
  (412×715) the layout was drawn against. Sizes written as `16.sp` / `12.h` /
  `8.r` scale proportionally, so the design holds on larger and smaller phones.
- **`provider`** — `ThemeProvider` sits above `MaterialApp`, so the theme chosen
  on the settings screen restyles the grid and details pages too. This is the app
  state lesson from Lab Activity 1 reused in a real app.

### Enhancements

Each is marked with an `ENHANCEMENT n` comment at its implementation site.

**Enhancement 1 — search bar above the product list.**
A `TextField` above the grid. Typing is debounced by 450 ms so a burst of
keystrokes produces one request rather than one per character, then
`ProductService.searchProducts()` calls `GET /products/search?q=…` — the filtering
is done by the API, not in the app. Clearing the field restores the full
catalogue. The query is passed through `Uri.encodeQueryComponent` so spaces and
symbols cannot break the URL.

**Enhancement 2 — details page when a card is tapped.**
`ProductDetailsScreen` receives the whole `Product` through its constructor, so
it renders without a second network call. It shows a swipeable image carousel with
dot indicators, the discounted price beside the struck-through original, a
five-star rating with half-star support, availability, the full specifications
table drawn from the nested model objects, tags, and the customer reviews list.

**Enhancement 3 — settings page holding the dark/light switch.**
Reached from the gear icon in the AppBar. The `SwitchListTile` is bound to
`ThemeProvider`, so one tap restyles every screen in the app.

### Verification

- `flutter analyze` — no issues.
- `flutter test` — 9 tests passing (model decoding, provider state, details page
  rendering).
- Run on an Android Pixel 3a emulator against the live API: catalogue load,
  search, details, settings, dark mode, empty-result state, offline error state,
  and recovery via **Retry**.
