# Estrategia de datos

## Fuentes prioritarias

1. Organismos oficiales españoles.
2. Comunidades autónomas, diputaciones y ayuntamientos.
3. Organismos europeos y científicos.
4. OpenStreetMap y otros proyectos abiertos compatibles con sus licencias.
5. Comunidad de usuarios, claramente etiquetada.

## Fuentes previstas

- IGN/CNIG para cartografía, nomenclátor, transporte, hidrografía y modelos del terreno disponibles mediante sus servicios y descargas.
- AEMET para meteorología y avisos.
- MITECO para biodiversidad, espacios protegidos e incendios cuando el dataset disponible sea adecuado.
- Administraciones autonómicas para restricciones, cierres y espacios naturales.

## Contrato de datos

Cada fuente integrada debe documentar:

- propietario;
- endpoint;
- licencia;
- atribución;
- frecuencia de actualización;
- límites de uso;
- cobertura;
- formato;
- contacto;
- plan de fallback;
- si requiere credencial y dónde se mantiene esa credencial;
- ventana de frescura y comportamiento cuando caduca.

## Frescura

Los datos dinámicos deben mostrar la hora de emisión, última actualización y, cuando exista, caducidad del proveedor. Si superan su ventana de validez, pasan a estado `stale` o `expired` y no deben presentarse como actuales. Una ausencia de datos no equivale a ausencia de riesgo.

## Autoridad

Las alertas deben conservar su autoridad de origen:

- `OFFICIAL`: emitida por un organismo competente.
- `ESPANA_OUTDOOR`: evaluación o aviso generado por el producto a partir de datos trazables.

España Outdoor nunca debe elevar una inferencia propia al nivel de una alerta oficial.

## No mezclar confianza

Una alerta oficial, un reporte comunitario y una inferencia de IA deben ser visualmente distinguibles y conservar su procedencia hasta la interfaz final.

## Credenciales y seguridad

Las credenciales de proveedores no deben incrustarse en el cliente móvil/web. Cuando un proveedor exige una API key, la integración de producción debe pasar por un gateway/backend controlado por España Outdoor, con rate limiting, rotación y observabilidad. El cliente recibe solamente el dato normalizado que necesita.

AEMET ofrece OpenData mediante API REST y también canales RSS/Atom para avisos meteorológicos; la arquitectura debe poder usar ambos mecanismos como adaptadores, no como contratos de UI. citehttps://www.aemet.es/es/datos_abiertos/AEMET_OpenData

IGN/CNIG publica servicios geográficos, incluyendo WFS, WCS y OGC API/descargas para distintos productos; deben evaluarse por dataset concreto y no asumirse licencias o coberturas idénticas entre productos. citehttps://www.ign.es/web/es/ign/portal/ide-area-nodo-ide-ign

## Cartografía OSM

Los servidores públicos de teselas de OpenStreetMap no son un backend de descargas offline. Para mapas descargables se usarán paquetes/licencias y proveedores que permitan explícitamente el uso offline, o infraestructura propia. La atribución visible seguirá siendo obligatoria cuando corresponda. citehttps://operations.osmfoundation.org/policies/tiles/
