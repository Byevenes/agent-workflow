# Zona horaria en integraciones

Pégala en el KDB del proyecto cliente. Un humano la revisa antes. No la copies a un repo cliente desde el repo de flujo.

## Marcas de una API externa

Trata las marcas de tiempo que devuelve una API externa como UTC, salvo que el contrato diga otra zona.

## Comparar en un solo reloj

Normaliza los dos lados a un mismo reloj (UTC) antes de comparar una ventana. No compares un instante en UTC con la hora local del servidor.

## Offset del proceso

Documenta el offset de ejecución, por ejemplo la variable `TZ`, y el efecto sobre una ventana de N horas. Si el proceso no corre en UTC, una ventana de N horas no es el mismo intervalo que en la API.
