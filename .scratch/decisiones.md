# Open decisions

The issue text does not settle these. The code does not pick for Classify.

## Commit-order gate on Large (#47)

Classify still chooses whether a Large run requires `scripts/check-commit-order.sh`. This change leaves the gate unwired from `scripts/check.sh`.

1. Optional. Classify marks the gate required only when the branch will have several commits and the cost is acceptable.
2. Required on every Large run before the work is called done.
3. Required only when `base..HEAD` contains more than one commit.

## Out-of-scope bug gate (#44)

zNinja stops and asks. An approved fix is a `fix:` commit before the feature commit. The acceptance criterion is that protocol plus a review checklist. It does not choose an automatic reject.

1. Checklist only. zNinja stops. zSensei checks that the `fix:` commit is an ancestor of the feature commit and that they are not the same commit.
2. A gate that fails a feature commit whose paths sit outside a file list named by the ticket. The ticket has to name those files.
3. A gate that fails when one commit subject is both `fix:` and `feat:`. That misses a mixed diff with a single subject.

Shipped the checklist from the acceptance criteria. Did not add a reject script.

# Decisiones abiertas (issue 55)

El issue no cierra estos forks. Esta corrida sigue lo que el texto sí dice y deja el resto escrito. Ninguna opción de aquí es una regla nueva en el skill.

## 1. Dónde vive el medidor

El issue dice Classify de zStack más `ztickets`, o una skill fina `zsizer`.

- Opción A, la que quedó en el diff: la fórmula, el promote y la ruta de seguridad están en la sección 1 de `skills/zstack/SKILL.md`. `ztickets` usa ese conteo y no copia la fórmula.
- Opción B: skill `skills/zsizer/SKILL.md`. Classify y `ztickets` solo apuntan.
- Opción C: la misma fórmula copiada en Classify y en `ztickets`.

## 2. Qué cuenta como estimación ≳150k

El issue escribe la fórmula con holgura y, aparte, "Medium con estimación ≳150k". No dice si el 150k es antes o después de la holgura.

- Opción A: promote cuando `tokens_estimados * holgura > 150_000` (el conteo sale mayor que 1).
- Opción B: promote cuando `tokens_estimados >= 150_000`. La holgura solo entra al conteo.
- Opción C, la que quedó en el diff: la frase es "about 150k tokens". No hay una comparación estricta nueva.

## 3. Holgura por defecto

- Opción A, la que quedó en el diff: no hay número. Quien estima escribe la holgura. Sin el número, la tarea no está lista.
- Opción B: 1.2 fijo.
- Opción C: 1.5 fijo.

## 4. Small por encima del presupuesto

- Opción A, la que quedó en el diff: solo un Medium sube a Large. Un Small sigue Small.
- Opción B: cualquier tamaño que no sea Critical y cuyo conteo sea mayor que 1 pasa a Large.

## 5. Archivo de calibración

El issue pide un lugar en `.scratch/` al cerrar, en la retro.

- Opción A, la que quedó en el diff: `.scratch/<slug>/calibracion.md`, campos en la sección 5 de zstack, lo escribe `zretro`.
- Opción B: una sección dentro de la nota de retro, sin archivo propio.
- Opción C: un solo `.scratch/calibracion.md` append-only para todas las tareas.
