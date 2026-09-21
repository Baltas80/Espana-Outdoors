# Estrategia de datos

## Fuentes prioritarias

1. Organismos oficiales españoles.
2. Comunidades autónomas, diputaciones y ayuntamientos.
3. Organismos europeos y científicos.
4. OpenStreetMap y otros proyectos abiertos compatibles con sus licencias.
5. Comunidad de usuarios, claramente etiquetada.

## Fuentes previstas

- IGN/CNIG para cartografía y datos geográficos.
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
- plan de fallback.

## Frescura

Los datos dinámicos deben mostrar la hora de última actualización. Si superan su ventana de validez, pasan a estado `stale` y no deben presentarse como actuales.

## No mezclar confianza

Una alerta oficial, un reporte comunitario y una inferencia de IA deben ser visualmente distinguibles.
