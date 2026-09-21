# Privacidad y seguridad

## Principios

- Minimización de datos.
- Privacidad desde el diseño y por defecto.
- Separación entre datos públicos, privados y de emergencia.
- Ubicación precisa solo cuando sea necesaria.
- Retención limitada.
- Cifrado en tránsito y reposo.
- Secretos fuera del repositorio.
- Auditoría de accesos administrativos.

## Ubicación

La app no debe convertir la localización en un seguimiento permanente por defecto. Deben existir estados separados para:

- uso puntual;
- navegación activa;
- compartir con contacto;
- emergencia;
- Rescue Link.

Cada estado debe poder revocarse cuando técnicamente sea posible.

## Rescue Link

Debe utilizar identificadores temporales, expiración, rate limiting, protección contra enumeración, bloqueo y denuncia. La ubicación exacta solo se comparte cuando exista una necesidad funcional legítima y autorización adecuada.

## Datos de fauna

No publicar coordenadas exactas de especies, nidos, madrigueras o hábitats sensibles cuando hacerlo pueda facilitar perturbación o daño.

## IA

La IA es asistiva. No puede inventar alertas oficiales, cierres, incendios, coordenadas ni instrucciones de emergencia. Las respuestas críticas deben poder vincularse a fuentes o declararse como estimaciones.

## Emergencias

La aplicación no garantiza rescate, cobertura, disponibilidad de GPS ni entrega de coordenadas a servicios externos. En una emergencia real se debe facilitar el acceso al 112.

## Revisión legal

Antes del lanzamiento comercial deben revisarse, según el tratamiento real: RGPD, LOPDGDD, LSSI-CE, DSA cuando resulte aplicable, AI Act cuando resulte aplicable, consumidores, accesibilidad, propiedad intelectual, licencias de datos y normativa ambiental/sectorial.
