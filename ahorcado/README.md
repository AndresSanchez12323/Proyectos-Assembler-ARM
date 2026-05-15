# Ahorcado (ARMv6)

Juego de Ahorcado en ensamblador ARMv6. Un jugador ingresa la palabra secreta y el otro intenta adivinarla letra por letra.

---

## Idea general

- Se guarda la palabra secreta en memoria.
- Se crea un estado visible con guiones bajos (`_`).
- El jugador propone letras hasta ganar o agotar intentos.

---

## Modelo de datos

- `secreta`: palabra a adivinar.
- `estado_actual`: version parcial con letras adivinadas.
- `letras_previas`: arreglo de 26 bytes para letras usadas.
- `contador_errores` y `limite_intentos`: control de fallos.

---

## Flujo principal

- `main` lee la palabra, calcula longitud y prepara el estado con `preparar_juego`.
- En cada turno se pide una letra, se normaliza a minuscula y se valida con `evaluar_letra`.
- `comprobar_final` decide victoria (no quedan `_`) o derrota (errores >= limite).

---

## Subrutinas clave

- `preparar_juego`: inicializa `estado_actual` con `_`.
- `evaluar_letra`: valida repetidas, busca coincidencias y actualiza contadores.
- `comprobar_final`: verifica victoria o derrota.
- `calcular_longitud`: obtiene el largo de la palabra secreta.

---

## Compilacion y ejecucion

Este programa usa `printf` y `scanf`, por lo que requiere enlazar con la biblioteca C. En ARM Linux suele compilarse con un compilador del toolchain (ejemplo):

```bash
gcc -o ahorcado ahorcado.s
./ahorcado
```

Si estas en un entorno cross, usa el compilador de tu toolchain ARM (por ejemplo `arm-linux-gnueabihf-gcc`).
