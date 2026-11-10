---
name: to-analysis
description: "Produce el análisis técnico previo a la implementación de una HU de cliente: lee el ticket, los repos involucrados y los KDBs, y deja hallazgos con evidencia, riesgos, supuestos y preguntas por prioridad para el TL/PO/Infra."
disable-model-invocation: true
---

A partir de una HU (historia de usuario del PO) o de un ticket, produce el **análisis técnico previo a la implementación**. Es el primer paso del flujo de HU de cliente:

**to-analysis** → preguntas al TL/PO/Infra (`client-questionnaire`) → respuestas en el ticket → `grill-with-docs` si quedan huecos → `to-techspec` → PRD → TD.

No diseña la solución final ni escribe código. Reúne evidencia y deja claro qué falta preguntar.

## Insumos

- **Obligatorio:** texto de la HU o clave del ticket.
- **Opcionales:** inventario de repositorios del cliente, KDBs/guidelines del cliente, repos ya clonados, análisis o PRDs previos, notas de reunión y cualquier insumo extra que entregue el usuario.

## Proceso

1. **Ticket.** Lee el ticket, **todos** sus comentarios y los adjuntos o requerimientos enlazados con el MCP de Atlassian, solo lectura. Nunca comentes, edites ni transiciones. Si el requerimiento cambia de versión, registra qué cambió.
2. **KDBs.** Lee los KDBs/guidelines del cliente que apliquen (arquitectura, persistencia, testing, despliegue, seguridad).
3. **Repos.** Identifica los repos involucrados desde el inventario del cliente e inspecciónalos: stack y versión del framework, endpoints y clientes HTTP existentes, modelo de datos, jobs/workers, tests y CI. **Cita cada hallazgo** (archivo, clase, endpoint, tabla). Lo que no encuentres en código es supuesto o pregunta, nunca un hecho.
4. **AS-IS / TO-BE.** Describe el comportamiento actual con evidencia y diagrama mermaid (usa `mermaid-diagrams` si está disponible). Propone alternativas TO-BE preliminares con su trade-off, sin cerrarlas.
5. **Preguntas.** Usa `client-questionnaire` para redactarlas. Sepáralas en **Alta / Media / Baja**, numeradas (Q1, Q2…) y con un dueño sugerido (TL, PO, Infra, QA). Marca aparte las que ya resolviste leyendo el código.

## Salida

Un `.md` junto a las notas de análisis del cliente, nombrado `<YYYY-MM-DD> Analisis tecnico <TICKET> <tema>.md`, con estas secciones:

1. **Resumen de la HU:** objetivo, actores, versión del requerimiento y fuentes (ticket, comentarios, adjuntos).
2. **Vocabulario de trabajo:** términos del dominio usados en el análisis.
3. **Sistemas e integraciones involucrados:** tabla `Sistema / repo | Rol | Stack y versión | Toca / no toca`, y por qué quedan fuera los que no aplican.
4. **Hallazgos en repos (AS-IS):** por tema, con citas a archivos y endpoints, más un diagrama.
5. **TO-BE preliminar:** alternativas, trade-offs y recomendación provisional.
6. **Riesgos:** tabla `Riesgo | Impacto | Mitigación`.
7. **Supuestos:** lo que se asume hasta confirmarlo.
8. **Preguntas para TL/PO/Infra:** por prioridad Alta / Media / Baja, numeradas y con dueño sugerido. Incluye un subconjunto de imprescindibles para la reunión y lo resuelto leyendo el código.
9. **Respuestas del TL:** sección reservada, vacía, para llenar después con `Pregunta | Respuesta | Fuente | Fecha`.
10. **Siguiente paso.**

## Reglas

- No inventes valores ni contratos. Lo desconocido va como pregunta o como "Por definir" con dueño.
- No incluyas secretos, credenciales ni connection strings.
- Si la nota ya existe, haz respaldo antes de editarla y agrega una sección de actualización fechada en vez de reescribirla.
- **Siguiente paso:** cuando lleguen las respuestas, completa la sección 9 y ejecuta `to-techspec`. Usa `grill-with-docs` antes si quedan huecos de diseño.
