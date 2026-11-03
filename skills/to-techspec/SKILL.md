---
name: to-techspec
description: "Genera una TechSpec que acompaña a la HU como insumo del PRD: alineamiento técnico previo a la implementación, a partir del ticket, las respuestas del TL/PO, los KDBs y los repos involucrados."
disable-model-invocation: true
---

Genera una **TechSpec**: el documento que **acompaña a la HU** (historia de usuario del PO) como **insumo del PRD**. No compite con el PRD ni con el TD. Es **alineamiento técnico previo a la implementación**: fija lo técnico ya acordado con TL/PO/Infra para que el PRD y el TD no inventen.

## Posición en el flujo

HU → análisis técnico con preguntas por prioridad (`to-questionnaire`) → respuestas del TL/PO (en el ticket) → `grill-with-docs` para cerrar huecos → **TechSpec** → PRD → TD → `prd-td-coherence` valida al final que PRD y TD respeten la TechSpec.

Si aún no hay respuestas del TL/PO, no generes la TechSpec: propone primero `to-questionnaire`.

## Insumos

- **Obligatorio:** texto de la HU o clave del ticket.
- **Opcionales:** análisis técnico previo, respuestas del TL en el ticket, notas de reunión, KDBs/guidelines del cliente, inventario de repositorios, repos involucrados, PRDs previos y cualquier insumo extra que entregue el usuario.

## Proceso

1. **Ticket.** Lee el ticket y **todos** sus comentarios con el MCP de Atlassian, solo lectura. Nunca comentes, edites ni transiciones.
2. **Estructura y KDBs.** Esta skill es la única fuente del formato: usa las secciones de "Salida" en ese orden y no busques una plantilla externa. Lee solo los KDBs y guidelines del cliente (arquitectura, persistencia, testing, despliegue) para el contenido.
3. **Análisis previo.** Si existe la nota de análisis del ticket, toma de ahí las preguntas, prioridades y respuestas. Cada decisión cerrada lleva fuente (comentario, reunión, KDB) y fecha.
4. **Repos.** Identifica los repos involucrados desde el inventario del cliente e inspecciónalos: stack y versión del framework, endpoints y contratos **realmente presentes en el código**, modelo de datos, tests existentes y CI/despliegue. **Nunca adivines un contrato:** cita el archivo, la clase o el endpoint encontrado. Si no está en el código, es "Por definir".
5. **Huecos.** Lo que siga abierto pasa a Pendientes con dueño y nivel de bloqueo. Si hay huecos de diseño, sugiere `grill-with-docs` antes de cerrar.
6. **Diagramas.** Usa la skill `mermaid-diagrams` si está disponible. Ver "Diagramas".
7. **Escribe** una sola TechSpec, neutral (ver "Neutralidad"). La trazabilidad va en el análisis técnico (ver "Trazabilidad"). Enlaza la TechSpec desde la nota de análisis.
8. **Pulido.** Aplica `technical-writing` y `unslop` a la TechSpec. Revisa "un dato, un lugar".
9. **Exportación (opcional, solo si el usuario la pide).** Genera una copia `.md` estándar de la TechSpec: sin frontmatter, sin wikilinks `[[...]]`, sin callouts `> [!...]`, sin embeds ni tags, y con cada diagrama también como imagen (PNG o SVG). La fuente sigue siendo el archivo original.

## Salida (secciones)

1. Contexto y alcance (dentro / fuera de alcance), con el diagrama o la tabla de alcance.
2. Límites y supuestos.
3. Definiciones: decisiones cerradas en voz neutra, sin fuente ni historia (la fuente queda en el análisis).
4. Reglas de negocio técnicas: tabla `ID | Regla | Lógica técnica y validación | Impacto en backend y frontend`. Cada regla es una frase con verbo y cita la decisión que la origina en lugar de repetirla.
5. Arquitectura: `sequenceDiagram` mermaid del cambio de riesgo. En frontend suma un `stateDiagram-v2` de la UI. Si aplica, la variante batch/worker (disparo, lotes, reintentos, idempotencia).
6. Modelo de datos y cambios de BD.
7. Contratos y APIs (request/response citando el código) e integraciones: tabla `Sistema o API | Propósito | Tipo de conexión`.
8. Errores y reintentos.
9. Seguridad.
10. Atributos de calidad: tabla `Atributo | Restricción o métrica | Implementación` (rendimiento, testing, disponibilidad).
11. Ambientes y despliegue.
12. Plan de pruebas, enlazando el KDB de testing del cliente (niveles, versiones, qué es unit y qué es integración). Declara la costura principal de prueba (la más alta posible, idealmente una) y describe los demás casos sobre ella.
13. Criterios de verificación técnicos (ver "Criterios").
14. Pendientes: tabla `ID | Pendiente | Dueño | Bloquea` con valores `bloquea TechSpec`, `bloquea PRD`, `bloquea implementación` o `no bloquea`.
15. Insumos para el PRD: qué debe tomar el PRD tal cual de esta TechSpec.

Secciones opcionales, antes del Registro de cambios:

- **Términos:** glosario breve cuando el ticket usa nombres de negocio que no coinciden con el código.
- **Rollback:** cómo revertir cada cambio de riesgo y qué queda igual.
- **Observaciones y oportunidades de mejora (fuera de alcance):** de 3 a 5 puntos con evidencia, sin compromisos. Aclara que cada uno requiere su propio requerimiento por el riesgo de regresión.

**Registro de cambios** siempre al final, después de cualquier sección opcional: versión, fecha y cambio, sin autor.

## Neutralidad

La TechSpec es una sola versión que puede salir del equipo tal cual.

- Sin nombres de personas, autores ni roles internos. El autor es "Equipo de desarrollo".
- Sin herramientas internas, asistentes, agentes, skills, IDEs ni bases de conocimiento internas.
- Sin rutas locales, commits, hashes, ramas, números de línea ni tickets de otros sistemas. El código se cita como clase o método relativo al repo.
- Sin historia de decisiones ni citas de conversaciones.
- Sin URLs, hosts ni credenciales.
- Antes de entregar, barre el archivo con `grep -niw` contra la lista de términos sensibles del proyecto y confirma 0 coincidencias.

## Trazabilidad

Quién decidió, fuentes y fechas, archivo y línea de código, evidencia, cadena de dependencias y lo que no se pudo verificar van en la nota de análisis técnico (`to-analysis`), en una sección "Trazabilidad TechSpec vX.Y". La TechSpec no incluye esa información. Si hace falta, la referencia de forma interna (por ejemplo, un enlace en la nota de análisis hacia la TechSpec), nunca en el cuerpo que se entrega.

## Diagramas

- Un diagrama por cambio de riesgo, no uno por flujo. Si un flujo no cambia de forma, no lleva diagrama.
- Cada diagrama tiene al lado una tabla equivalente, por si el destino no renderiza mermaid (Word, PDF y algunos portales no lo hacen).
- Valida la sintaxis con `mmdc` (`npx -y @mermaid-js/mermaid-cli`) cuando esté disponible. Si no, revísala a mano y dilo.

## Criterios

- **Criterios de verificación** (§13): técnicos y comprobables en el sistema (un campo en el payload, una línea en el log, un contrato que no cambia).
- **Criterios de aceptación** de negocio: pertenecen al PRD. No los escribas aquí.

## Reglas

- **No inventes valores.** Lo desconocido va como "Por definir" con dueño (TL, PO, Infra, QA).
- **Un dato, un lugar.** Cada ID, regla o caso vive en una sola sección; las demás la citan (por ejemplo "D-03" o "§7.1").
- **Backend vs frontend:** en backend prioriza contratos, BD, workers y reintentos. En frontend prioriza estados de UI, componentes, rutas, accesibilidad y consumo de APIs.
- **Versionado:** `v0.x` (Borrador) mientras haya pendientes que bloqueen el PRD; `v1.0` cuando se cierren todos. Cada cambio de alcance o de decisión sube la versión menor (`v1.1`). Un ajuste de forma o de verificación que no cambia alcance ni decisiones mantiene la versión: no agrega fila al registro de cambios; el detalle queda en la trazabilidad del análisis.
- **Nombre del archivo:** `<YYYY-MM-DD> <TICKET> TechSpec vX.Y.md`, junto a las notas de análisis. Antes de subir de versión, renombra la anterior a `<YYYY-MM-DD> <TICKET> TechSpec.vX.Y.bak.md`. Agrega el enlace de vuelta en la nota de análisis.
- No dupliques el PRD (criterios de aceptación, UX detallada) ni el TD (diseño de clases, tareas).
- No incluyas secretos, credenciales ni connection strings.
- Al cerrar, resume las decisiones, los pendientes que bloquean y el siguiente paso (PRD o una nueva ronda de preguntas).
