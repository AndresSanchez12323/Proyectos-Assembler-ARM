# Serie de Fibonacci (ARMv6)

Calculo iterativo del termino N de Fibonacci en ensamblador ARMv6. El resultado se guarda en memoria.

---

## Idea general

- `Numero` contiene N.
- Si `N <= 1`, se almacena directamente.
- Caso general: se itera con `R1` y `R2` como F(n-2) y F(n-1).
- El resultado final se guarda en `Resultado`.

---

## Flujo principal

- Carga `Numero` desde `.DATA`.
- Inicializa `R1 = 0` y `R2 = 1`.
- En cada ciclo calcula el siguiente termino y avanza la ventana.
- Termina con `WFI` (espera de interrupcion).

---

## Compilacion y ejecucion

Ejemplo con assembler y linker en ARMv6:

```bash
as -march=armv6 -o fibonacci.o "Serie Fibonacci.s"
ld -o fibonacci fibonacci.o
./fibonacci
```

Nota: el programa no imprime el resultado; lo deja en memoria en `Resultado`.
