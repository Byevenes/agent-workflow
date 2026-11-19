# Insumos QA: ACME-123 Campo de referencia en solicitudes

Borrador interno. Lo produce zStack al cerrar el desarrollo de una tarea de cliente. Otro actor lo usa para armar la entrega a QA del cliente, con el ok de Brayan. Cursor no publica este archivo ni escribe en Jira ni en Confluence. Sin datos personales, credenciales ni identificadores reales de clientes.

## Funcionalidades modificadas

| N° | Funcionalidad | Qué cambia |
|---|---|---|
| 1 | Cambio de dirección | La solicitud envía el campo "Referencia" junto con "Contrato" |
| 2 | Solicitud de certificado | Igual que la 1 |
| 3 | Alerta por descarga de documento | La alerta suma el campo "Referencia" |

## Dónde se gatillan

| N° | Pantalla o acción | Endpoint |
|---|---|---|
| 1 | Mi perfil > Dirección > botón "Guardar" | `POST /v2/address/change` |
| 2 | Mis documentos > "Pedir certificado" | `POST /v2/certificate/request` |
| 3 | Detalle del contrato > "Descargar" | `GET /v2/contract/{id}/download` |

## Referencia al código

| N° | Archivo y línea | Commit |
|---|---|---|
| 1 | `src/Address/ChangeAddressService.cs:88` | `abc1234` |
| 2 | `src/Certificates/RequestService.cs:41` | `abc1234` |
| 3 | `src/Alerts/DownloadAlert.cs:23` | `def5678` |

La referencia al código es interna. El texto que se publica en el sistema del cliente usa solo la funcionalidad y dónde se gatilla.

## Fuera de alcance

- Cambio de plan: la solicitud no crea ticket.
- Versiones antiguas de las pantallas, que usan otro endpoint.
- Solicitudes que ya enviaban ambos campos.

## Casos de QA sugeridos

| N° | Caso | Resultado esperado |
|---|---|---|
| 1 | Guardar una dirección nueva | El ticket trae "Referencia" y "Contrato" con el mismo valor |
| 2 | Pedir un certificado | Igual que el caso 1 |
| 3 | Descargar el documento del contrato | La alerta trae "Referencia" con el número de contrato |

Cruza cada caso con su endpoint, no solo por nombre: dos pantallas con el mismo nombre pueden usar endpoints distintos. Si el resultado esperado del equipo de QA contradice el código, anótalo aquí antes de la entrega.
