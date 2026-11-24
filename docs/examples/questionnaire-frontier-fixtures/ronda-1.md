## Preguntas
Q1. ¿El reporte mensual se exporta en CSV o en XLSX? dueño:PO
  estado:pendiente bloqueante:sí depende de:-
Q2. ¿El separador del CSV es coma o punto y coma? dueño:TL
  estado:pendiente bloqueante:sí depende de:Q1
Q3. ¿El reporte incluye filas sin categoría? dueño:PO
  estado:pendiente bloqueante:sí depende de:-
Q4. ¿Qué tabla guarda la fecha de corte del reporte? dueño:TL
  estado:respondida bloqueante:sí depende de:-
Q5. ¿La exportación corre en el mismo job nocturno que hoy? dueño:Infra
  estado:pendiente bloqueante:sí depende de:Q4
Q6. ¿El nombre del archivo lleva la fecha de corte? dueño:QA
  estado:pendiente bloqueante:no depende de:Q1
Q7. ¿Se mantiene el envío por correo del reporte antiguo? dueño:PO
  estado:obsoleta bloqueante:no depende de:-
Q8. ¿Cuántas filas tiene un mes típico? dueño:QA
  estado:pendiente bloqueante:no depende de:-

## Ronda actual
- Q1
- Q3
- Q5

## Prioridad
Q1, Q3 y Q5 son Alta. Q2 es Media. Q6 y Q8 son Baja.

## Bloqueantes
Q1, Q3 y Q5 bloquean el TechSpec. Q2 espera a Q1. Q7 quedó obsoleta: el spec nuevo saca el envío por correo.
