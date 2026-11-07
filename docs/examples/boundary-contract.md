# Sample diff

This sample is not a change to apply.

The sample has two modules.

`quote.ts` returns `totalCents`. That field is an integer count of minor units. The function adds each line's `unitCents` times `qty` and returns the sum. The body matches its own contract.

`charge.ts` reads a field named `total`. It treats `total` as a decimal amount in major units. The function multiplies `total` by 100. The body matches its own contract.

The call passes the quote result into `chargeTotal` by writing `totalCents` into `total`. That sends cents where major units are expected. A quote of 1999 minor units becomes 199900 after the multiply. A review must flag that boundary even though each module looks consistent alone.

```diff
--- a/quote.ts
+++ b/quote.ts
@@ -0,0 +1,8 @@
+type Line = {
+	unitCents: number
+	qty: number
+}
+
+export function quoteTotal(lines: Line[]): { totalCents: number } {
+	const totalCents = lines.reduce((sum, line) => sum + line.unitCents * line.qty, 0)
+	return { totalCents }
+}
--- a/charge.ts
+++ b/charge.ts
@@ -0,0 +1,3 @@
+export function chargeTotal(order: { total: number }): number {
+	return Math.round(order.total * 100)
+}
--- a/call.ts
+++ b/call.ts
@@ -0,0 +1,2 @@
+const quoted = quoteTotal(lines)
+chargeTotal({ total: quoted.totalCents })
```
