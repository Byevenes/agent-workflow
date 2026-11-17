---
name: client-questionnaire
description: "Produce el cuestionario de un entregable de cliente para que TL y PO respondan antes del TechSpec."
disable-model-invocation: true
---

Produce el cuestionario que TL y PO responden antes del TechSpec.

1. Lee el análisis. Cada pregunta pide un dato que el análisis todavía no asume. Listo cuando cada pregunta nace de un hueco distinto.
2. Escribe el documento con la plantilla de abajo. El rol de cada línea es TL, PO, Infra o QA. Listo cuando hay una idea por línea.
3. El tope por dueño lo aplica `scripts/check-draft-sections.sh` y se configura con `ZSTACK_MAX_QUESTIONS_PER_OWNER` (default 15). No pidas un número a Brayan antes de redactar.

## Preguntas
Q1. ¿El informe incluye filas sin estado? dueño:QA

## Prioridad
Q1 es Alta.

## Bloqueantes
Q1 bloquea el TechSpec.
