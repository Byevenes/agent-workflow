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
