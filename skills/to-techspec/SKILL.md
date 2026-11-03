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
2. **Plantilla y KDBs.** Ubica la plantilla TechSpec del cliente y sus KDBs/guidelines (arquitectura, persistencia, testing, despliegue). Si no hay plantilla, usa las secciones de "Salida" en ese orden.
3. **Análisis previo.** Si existe la nota de análisis del ticket, toma de ahí las preguntas, prioridades y respuestas. Cada decisión cerrada lleva fuente (comentario, reunión, KDB) y fecha.
4. **Repos.** Identifica los repos involucrados desde el inventario del cliente e inspecciónalos: stack y versión del framework, endpoints y contratos **realmente presentes en el código**, modelo de datos, tests existentes y CI/despliegue. **Nunca adivines un contrato:** cita el archivo, la clase o el endpoint encontrado. Si no está en el código, es "Por definir".
5. **Huecos.** Lo que siga abierto pasa a Pendientes con dueño y nivel de bloqueo. Si hay huecos de diseño, sugiere `grill-with-docs` antes de cerrar.
6. **Diagramas.** Usa la skill `mermaid-diagrams` si está disponible.
7. **Escribe** la TechSpec y enlázala desde la nota de análisis.

## Salida (secciones de la plantilla)

1. Contexto y alcance (dentro / fuera de alcance).
2. Límites y supuestos.
3. Decisiones cerradas, con fuente y fecha.
4. Reglas de negocio técnicas: tabla `ID | Regla | Lógica técnica / validación | Impacto backend / frontend`.
5. Arquitectura: `sequenceDiagram` mermaid. En frontend suma un `stateDiagram-v2` de la UI. Si aplica, la variante batch/worker (disparo, lotes, reintentos, idempotencia).
6. Modelo de datos y cambios de BD.
7. Contratos y APIs (request/response citando el código) e integraciones: tabla `Sistema / API | Propósito | Tipo de conexión`.
8. Errores y reintentos.
9. Seguridad.
10. Atributos de calidad: tabla `Atributo | Restricción / métrica | Implementación` (rendimiento, testing, disponibilidad).
11. Ambientes y despliegue.
12. Plan de pruebas, enlazando el KDB de testing del cliente (niveles, versiones, qué es unit y qué es integración).
13. Pendientes: tabla `ID | Pendiente | Dueño | Bloquea` con valores `bloquea TechSpec`, `bloquea PRD`, `bloquea implementación` o `no bloquea`.
14. Insumos para el PRD: qué debe tomar el PRD tal cual de esta TechSpec.
15. Registro de cambios.

## Reglas

- **No inventes valores.** Lo desconocido va como "Por definir" con dueño (TL, PO, Infra, QA).
- **Backend vs frontend:** en backend prioriza contratos, BD, workers y reintentos. En frontend prioriza estados de UI, componentes, rutas, accesibilidad y consumo de APIs.
- **Versionado:** `v0.x` (Borrador) mientras haya pendientes que bloqueen el PRD. Pasa a `v1.0` cuando se cierren todos.
- **Nombre del archivo:** `TechSpec <TICKET> <tema>.md`, junto a las notas de análisis del cliente. Agrega el enlace de vuelta en la nota de análisis.
- No dupliques el PRD (criterios de aceptación, UX detallada) ni el TD (diseño de clases, tareas).
- No incluyas secretos, credenciales ni connection strings.
- Al cerrar, resume las decisiones, los pendientes que bloquean y el siguiente paso (PRD o una nueva ronda de preguntas).
