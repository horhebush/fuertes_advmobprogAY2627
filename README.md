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

