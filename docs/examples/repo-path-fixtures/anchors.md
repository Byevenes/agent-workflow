# Anchors and links that resolve

See `src/Foo/Bar.cs:12`, `src/Foo/Bar.cs:12-20`, `src/Foo/Bar.cs#L12`, and `src/Foo/Bar.cs#L12-L20`.

See `README.md:1`.

Link [bar](src/Foo/Bar.cs), [line](src/Foo/Bar.cs#L12), and [range](README.md#L1-L3).

Skip [web](https:///a.md), [plain](http:///a.md), [mail](mailto:box.md), and [jump](#section).

Globs `src/**/*.cs`, `src/Foo/?.cs`, and `src/Foo/[Bb]ar.cs`, plus [glob](src/**/*.cs).

```text
Sample only: `src/NotACitation.cs:12` and [missing](src/Missing.cs).
```
