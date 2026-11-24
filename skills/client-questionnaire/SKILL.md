---
name: client-questionnaire
description: "Produce el cuestionario de un entregable de cliente para que TL y PO respondan antes del TechSpec."
disable-model-invocation: true
---

1. Lee el análisis. Cada pregunta pide un dato que el análisis todavía no asume. Listo cuando cada pregunta nace de un hueco distinto.
2. Escribe el documento con la plantilla de abajo. El rol de cada línea es TL, PO, Infra o QA. Listo cuando hay una idea por línea.
3. Bajo cada pregunta va una línea de estado: `estado:<pendiente|respondida|obsoleta> bloqueante:<sí|no> depende de:<Qn,Qm|->`. `depende de` lista las preguntas cuya respuesta cambia esta. Listo cuando cada pregunta tiene su línea de estado.
4. Emite solo la frontera en `## Ronda actual`, una línea `- Qn` por pregunta. La frontera son las preguntas `pendiente` con `bloqueante:sí` cuyas dependencias están todas `respondida` (o sin dependencias). Una pregunta `bloqueante:no` sale recién cuando no queda ninguna bloqueante en la frontera. Una pregunta que depende de otra `pendiente` espera la ronda siguiente. Listo cuando la ronda no tiene preguntas bloqueadas ni le falta una bloqueante lista.
5. Cuando llegan respuestas o cambia el spec, actualiza el estado en el mismo markdown: `respondida` si el spec o una respuesta ya la cubre, `obsoleta` si dejó de aplicar. No borres la pregunta. Recalcula `## Ronda actual`. Si una dependencia quedó `obsoleta`, reescribe o marca obsoleta la pregunta que dependía de ella. No hay tablero ni UI: el estado vive en este archivo.
6. El tope por dueño lo aplica `scripts/check-draft-sections.sh` y se configura con `ZSTACK_MAX_QUESTIONS_PER_OWNER` (default 15). Con `## Ronda actual` cuenta solo las preguntas `pendiente` de cada dueño. No pidas un número a Brayan antes de redactar.

## Preguntas
Q1. ¿El informe incluye filas sin estado? dueño:QA
  estado:pendiente bloqueante:sí depende de:-
Q2. ¿Las filas sin estado van al final del informe? dueño:PO
  estado:pendiente bloqueante:sí depende de:Q1

## Ronda actual
- Q1

## Prioridad
Q1 es Alta. Q2 es Media.

## Bloqueantes
Q1 bloquea el TechSpec. Q2 espera a Q1.
