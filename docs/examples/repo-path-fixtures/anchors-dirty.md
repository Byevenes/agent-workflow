# Anchors and links that must fail

Missing file with a long line anchor: `src/Missing.cs#L12-L20`.

Missing link with a colon range: [gone](src/LinkMissing.cs:12-20).

Ignored glob: `src/**/*.cs` and [glob](src/**/*.cs).

Ignored web: [web](https:///a.md) and [plain](http:///a.md).

Ignored mail: [mail](mailto:box.md).

Ignored anchor: [jump](#section).
