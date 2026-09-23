# ADR-0004 — Autoridad y frescura de alertas

- Estado: aceptado
- Fecha: 2026-09-23
- Ámbito: meteorología, incendios, inundaciones, nieve, viento, calor, terremotos, tsunami, volcanes, desprendimientos y otros riesgos

## Contexto

España Outdoor combina fuentes oficiales, fuentes abiertas, observaciones comunitarias y evaluaciones propias. Mezclarlas sin conservar autoridad y frescura puede producir una falsa sensación de seguridad.

## Decisión

1. Todo aviso se normaliza mediante un contrato provider-neutral.
2. La autoridad se conserva como `OFFICIAL` o `ESPANA_OUTDOOR`.
3. Cada aviso conserva emisión, última actualización y expiración cuando el proveedor la ofrece.
4. Un aviso sin expiración explícita no se considera indefinidamente actual: el adaptador debe aplicar una política conservadora de frescura y puede imponer un TTL específico por fuente.
5. Los estados de frescura son `CURRENT`, `STALE`, `EXPIRED` y `UNKNOWN`.
6. `UNKNOWN` nunca se convierte automáticamente en seguro.
7. La UI debe mostrar fuente, hora y autoridad; una evaluación de España Outdoor no puede representarse visualmente como una alerta oficial.
8. La lógica de "¿PUEDO HACER ESTA RUTA HOY?" consume estos contratos y debe degradar de forma segura cuando falten datos.

## Consecuencias

- Permite incorporar AEMET, Protección Civil, administraciones autonómicas y otras fuentes sin acoplar la UI a sus formatos.
- Permite fallback entre proveedores sin perder trazabilidad.
- Facilita pruebas deterministas de caducidad y datos ausentes.
- Obliga a tratar la ausencia o antigüedad de datos como incertidumbre, no como seguridad.

## Seguridad

Las API keys y credenciales de proveedores no deben almacenarse en el cliente. En producción, los proveedores que requieran credenciales deben consumirse mediante un gateway/backend con rate limiting, rotación y observabilidad.

## Relación con otras decisiones

- ADR-0001 — mapas y offline.
- ADR-0002 — gateway de datos dinámicos.
- ADR-0003 — proveedor de mapas offline.
