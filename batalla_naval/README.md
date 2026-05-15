# Batalla Naval (ARMv6)

Juego de Batalla Naval para 2 jugadores en ensamblador ARMv6. Usa syscalls de Linux y una terminal con secuencias ANSI para limpiar pantalla.

---

## Idea general

El juego tiene 3 fases:

1) Jugador 1 coloca sus 5 barcos.
2) Jugador 2 coloca sus 5 barcos.
3) Se alternan turnos hasta que un jugador queda sin vidas.

Cada tablero es una matriz de 8x8 almacenada como arreglo lineal de 64 bytes.

---

## Modelo de datos

- `mapa_j1` y `mapa_j2`: tableros (64 bytes cada uno).
- Estado por casilla:
  - `0`: agua
  - `1`: barco intacto
  - `2`: disparo fallido
  - `3`: barco impactado
- `vidas_j1` / `vidas_j2`: total de casillas vivas por jugador.

---

## Flujo principal

- `_start` llama a `principal`.
- `limpiar_mapas` inicializa tableros y vidas.
- `poner_barcos` pide coordenadas y orientacion (`h` / `v`) y valida con `colocar_logica`.
- En batalla, `leer_coord` traduce `A1`..`H8` a indice 0..63 y `procesar_disparo` actualiza el estado.

---

## Subrutinas clave

- `leer_coord`: valida y convierte coordenadas.
- `colocar_logica`: comprueba limites/choques y escribe barcos.
- `dibujar_mapas`: imprime tablero propio y radar enemigo.
- `procesar_disparo`: maneja agua, tocado o repetido.
- `division_mod`: division manual (sin hardware de division).

---

## Compilacion y ejecucion

Ver comandos en `Comandos.md` (pueden variar segun tu toolchain ARMv6). Ejemplo con `as`/`ld`:

```bash
as -march=armv6 -o batalla_naval.o batalla_naval.s
ld -o batalla_naval batalla_naval.o
chmod +x batalla_naval
./batalla_naval
```

---

## Notas ARMv6

- Se evita depender de division por hardware.
- Se respeta la alineacion de pila y registros callee-saved.
- La salida usa syscalls (`sys_write`) y entrada con `sys_read`.
