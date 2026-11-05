# Nota de entrega

## Qué cambió

El servicio acepta eventos cuya marca de tiempo cae dentro de la ventana de dos horas publicada en el contrato.

## Cómo verificar

1. Enviar un evento de prueba a https://example.com/api con una marca dentro de la ventana.
2. Confirmar que la respuesta es 200 y que el evento queda registrado.

## Riesgos o confirmaciones pendientes

Confirmar con el equipo el horario de corte del ambiente de pruebas en example.com.
