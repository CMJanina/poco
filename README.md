# poco

Generate compose files from portable mappings.

`poco` takes a simple YAML mapping of trigger sequences to replacement text and
turns it into a native compose file for a target platform. It is written in
Haskell and is currently a work in progress.

## Usage

```
poco [-t|--target TARGET] <input.yaml>
```

Example input file (see also: `example.yaml`):

```yaml
"ae": "ä"
"oe": "ö"
"ue": "ü"
"hug": "🫂"
"..": "…"
```

Run `poco` on the bundled example and compare with the expected output:

```
stack build
stack exec poco-exe -- example.yaml
diff example.dict <(stack exec poco-exe -- example.yaml)
diff example.compose <(stack exec poco-exe -- -t XComp example.yaml)
```

XCompose output can be validated with `libxkbcommon`:

```
xkbcli compile-compose <(stack exec poco-exe -- -t XComp example.yaml)
```

### Targets

| `TARGET` | Output                                                                                                                                                                                  | Status      |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `Cocoa`  | [`DefaultKeyBinding.dict`](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/TextDefaultsBindings/TextDefaultsBindings.html) for macOS (default) | implemented |
| `XComp`  | [`XCompose`](https://manned.org/man.3c6fbf56/arch/Compose.5) file for X11                                                                                                               | implemented |

Cocoa output deliberately mimics the Python tool
[`gen-compose`](https://github.com/Granitosaurus/macos-compose). For example,
`"hug": "🫂"` becomes:

```
{"§" = {
  "h" = {
    "u" = {
      "g" = ("insertText:", "🫂");
    };
  };
};}
```

`example.dict` shows the full `gen-compose` output for `example.yaml`.
It currently differs from `poco -t Cocoa` output in sorting.

## Notes

- No trigger sequence may be a prefix of another. Both targets reject inputs
  such as `"a"` and `"ab"`, but allow shared prefixes such as `"abc"` and `"abd"`.
- XCompose sequences match keysyms produced by the active keyboard layout.
  They do not require US key positions, but the layout must provide the expected
  symbols. Dead keys such as `dead_grave` do not match `grave`, and generated
  Unicode keysyms may differ from the layout's legacy keysyms. See
  [Compose(5)](https://xorg.freedesktop.org/archive/X11R7.5/doc/man/man5/Compose.5.html),
  [XkbKeycodeToKeysym(3)](https://www.x.org/releases/X11R7.5/doc/man/man3/XkbKeycodeToKeysym.3.html),
  and the [X11 keysym definitions](https://xorg.freedesktop.org/archive/X11R7.7/doc/xproto/x11protocol.html#Keysyms).
- XCompose results contain only strings, without an accompanying keysym.
  Applications that require a result keysym may fail to handle this input.
  For single-character results, emitting both, such as `"ä" adiaeresis`, could
  improve compatibility. Multi-character results generally have no corresponding
  single keysym. See [Compose(5)](https://xorg.freedesktop.org/archive/X11R7.5/doc/man/man5/Compose.5.html)
  for the result syntax and [XmbLookupString(3)](https://www.x.org/archive/X11R7.5/doc/man/man3/XmbLookupString.3.html)
  for the distinction between `XLookupChars` and `XLookupBoth`.
