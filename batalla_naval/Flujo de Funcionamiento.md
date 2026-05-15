# Batalla Naval en ARMv6 (Assembly)

Este proyecto implementa el juego de Batalla Naval para 2 jugadores en lenguaje ensamblador ARMv6.

El objetivo de este README es que una persona universitaria que recien esta aprendiendo ensamblador pueda entender:

- Como esta organizado el codigo.
- Por que se usan ciertas instrucciones (por ejemplo: `BL`, `BEQ`, `BNE`, `CMP`, `PUSH`, `POP`).
- Como fluye el juego internamente.
- Como compilar y ejecutar.

---

## 1) Idea general del programa

El programa tiene 3 fases:

1. Jugador 1 coloca sus 5 barcos.
2. Jugador 2 coloca sus 5 barcos.
3. Comienza la batalla por turnos hasta que uno llegue a 0 vidas.

Cada tablero es una matriz de 8x8 (64 casillas), guardada en memoria como un arreglo lineal.

---

## 2) Estructura principal del archivo `batalla_naval.s`

El archivo esta dividido en secciones clasicas de ensamblador:

- `.data`: textos, arreglos de tamanos, tableros y variables globales.
- `.text`: funciones y logica ejecutable.
- `_start`: punto de entrada del programa.

Funciones importantes:

- `principal`: orquesta todo el flujo del juego.
- `poner_barcos`: bucle para colocar barcos de un jugador.
- `colocar_logica`: valida colisiones y escribe barcos en el tablero.
- `procesar_disparo`: aplica un disparo y actualiza estado.
- `dibujar_mapas`: imprime tablero propio y radar enemigo.
- `leer_coord`: convierte entrada tipo `A5` a indice 0..63.
- `division_mod`: division entera manual (sin depender de instrucciones modernas).

---

## 3) Modelo de datos en memoria

### 3.1 Tableros

Se usan dos arreglos de 64 bytes:

- `mapa_j1`
- `mapa_j2`

Cada casilla guarda un estado:

- `0`: agua sin tocar
- `1`: barco
- `2`: disparo fallado
- `3`: barco impactado

### 3.2 Vidas

- `vidas_j1`: cantidad de casillas de barco vivas de J1.
- `vidas_j2`: cantidad de casillas de barco vivas de J2.

Cuando hay impacto, la vida del jugador objetivo disminuye en 1.

### 3.3 Conversion de coordenadas

Si el usuario escribe `A1`:

- Columna `A` -> 0
- Fila `1` -> 0
- Indice lineal = `fila * 8 + columna`

Formula general:

`indice = fila * MUNDO + columna`

Donde `MUNDO = 8`.

---

## 4) Flujo de ejecucion (resumen)

### 4.1 Entrada

`_start` llama a `principal`.

### 4.2 Inicializacion

`limpiar_mapas` pone en 0 los tableros y vidas.

### 4.3 Colocacion de barcos

`poner_barcos`:

- Toma cada tamano de `lista_tam`.
- Pide coordenada y orientacion (`h` o `v`).
- Llama a `colocar_logica`.
- Si falla (choque o fuera de rango), vuelve a pedir.

### 4.4 Batalla

En cada turno:

- Se limpia pantalla.
- Se muestra tablero y marcador.
- Se pide disparo.
- `procesar_disparo` retorna:
  - `0`: agua
  - `1`: tocado
  - `2`: repetido
- Se revisa si alguien llego a 0 vidas.
- Se cambia turno.

---

## 5) Instrucciones ARM clave explicadas (con contexto)

## 5.1 `BL` (Branch with Link)

Sirve para llamar funciones.

- Salta a otra etiqueta.
- Guarda la direccion de retorno en `LR`.

Ejemplo conceptual:

```asm
bl poner_barcos
```

Despues, la funcion vuelve con:

```asm
bx lr
```

---

## 5.2 `B`, `BEQ`, `BNE`, `BGT`, `BLT`

Son saltos para controlar flujo (if, else, while, for).

- `B etiqueta`: salto incondicional.
- `BEQ etiqueta`: salta si la comparacion fue igual.
- `BNE etiqueta`: salta si fue distinto.
- `BGT etiqueta`: salta si fue mayor.
- `BLT etiqueta`: salta si fue menor.

Siempre van despues de `CMP`.

Ejemplo conceptual:

```asm
cmp r4, #1
beq turno_j1
b turno_j2
```

Esto equivale a un `if (r4 == 1) ... else ...`.

---

## 5.3 `CMP`

Compara dos operandos y actualiza banderas del procesador (flags).

No guarda resultado en registro, solo afecta banderas para que un salto condicional decida.

Ejemplo:

```asm
cmp r0, #0
beq coord_invalida
```

---

## 5.4 `PUSH` y `POP`

Se usan para guardar/restaurar registros en pila.

Por que se usan:

- Evitar perder valores al llamar subrutinas.
- Cumplir convencion de llamada ARM (AAPCS).
- Mantener alineacion de pila a 8 bytes (muy importante en ARM antiguo).

Ejemplo:

```asm
push {r4-r11, r12, lr}
...
pop {r4-r11, r12, lr}
```

---

## 5.5 `LDR`, `LDRB`, `STR`, `STRB`

Acceso a memoria.

- `LDR`: carga palabra (32 bits).
- `STR`: guarda palabra (32 bits).
- `LDRB`: carga byte (8 bits).
- `STRB`: guarda byte (8 bits).

Como cada casilla del tablero es un byte, se usa mucho `LDRB/STRB`.

---

## 5.6 `SWI` (Syscall)

Permite llamar servicios del sistema operativo Linux (leer, escribir, salir).

En este proyecto se usa para:

- Leer teclado (`sys_read`, numero 3).
- Escribir en pantalla (`sys_write`, numero 4).
- Salir (`sys_exit`, numero 1).

En ARM clasico, el numero de syscall va en `R7`.

---

## 5.7 `MOV`, `ADD`, `SUB`, `MUL`

Aritmetica basica y movimiento de datos.

- `MOV`: copiar valor.
- `ADD`: suma.
- `SUB`: resta.
- `MUL`: multiplicacion.

Se usan para calcular indices y recorrer arreglos.

---

## 6) Equivalencia con estructuras de alto nivel

En ensamblador no existen `if`, `for`, `while` como palabras reservadas. Se construyen con etiquetas + comparaciones + saltos.

### 6.1 `if / else`

Patron:

```asm
cmp r0, #valor
beq etiqueta_if
b etiqueta_else
```

### 6.2 `while`

Patron:

```asm
bucle:
    cmp r1, #limite
    beq fin
    ...
    b bucle
fin:
```

### 6.3 `for`

Es el mismo concepto que `while`, pero con contador explicito (`add rX, rX, #1`).

---

## 7) Por que el codigo esta escrito asi

Este estilo es adecuado para ARMv6 y entornos viejos porque:

- Evita instrucciones no soportadas por CPUs mas nuevas/viejas incompatibles.
- Usa division manual (`division_mod`) en lugar de depender de hardware de division.
- Cuida alineacion de pila y datos para evitar errores de ejecucion.
- Separa responsabilidades en subrutinas pequenas y legibles.

---

## 8) Compilacion y ejecucion

## 8.1 En un entorno cross (ejemplo con `arm-none-eabi-*`)

```bash
arm-none-eabi-as -g -o batalla_naval.o batalla_naval.s
arm-none-eabi-ld -o batalla_naval batalla_naval.o
```

## 8.2 En Raspberry Pi (si compilas nativo)

```bash
as -o batalla_naval.o batalla_naval.s
ld -o batalla_naval batalla_naval.o
chmod +x batalla_naval
./batalla_naval
```

---

## 9) Consejos para estudiar este codigo (nivel universitario inicial)

1. Sigue primero solo el flujo de `principal`.
2. Luego estudia `leer_coord` y verifica como transforma `A1` en indice.
3. Despues analiza `colocar_logica` (primero valida, luego escribe).
4. Finalmente revisa `procesar_disparo` y las transiciones de estado 0,1,2,3.

Si entiendes esas 4 partes, ya entiendes casi todo el proyecto.

---

## 10) Mini glosario rapido

- **Etiqueta**: nombre de una posicion de codigo (ejemplo: `bucle_juego:`).
- **Subrutina**: bloque reutilizable llamado con `BL`.
- **LR (Link Register)**: guarda direccion de retorno de una llamada.
- **SP (Stack Pointer)**: puntero a la pila.
- **Callee-saved**: registros que una funcion debe restaurar si los modifica.
- **Syscall**: llamada al kernel para entrada/salida.

---

## 11) Creditos academicos sugeridos

Puedes documentar en tu entrega que el proyecto practica:

- Manejo de memoria lineal para modelar matrices.
- Control de flujo en ensamblador con banderas.
- Llamadas a subrutinas y convencion de llamada ARM.
- Entrada/salida por syscalls Linux.
- Validacion de datos de usuario en bajo nivel.
- Implementacion de logica de juego con estructuras basicas (if, while) en ensamblador.
- Uso de pila para preservar estado entre llamadas.
- Implementacion de division entera manual para compatibilidad.
