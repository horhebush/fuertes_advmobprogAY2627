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
