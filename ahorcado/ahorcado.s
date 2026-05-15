.data
.align 4
secreta: .space 32
long_secreta: .word 0
limite_intentos: .word 6
contador_errores: .word 0
contador_aciertos: .word 0

txt_ingresa_palabra: .asciz "Shhh... Escribe la palabra secreta: "
formato_palabra: .asciz "%s"

txt_titulo: .asciz "\n=== EL RETO DEL AHORCADO ===\n\n"
txt_palabra: .asciz "¿Cuál será la palabra misteriosa?: "
txt_intentos: .asciz "Te has equivocado %d de %d veces\n"
txt_ingresa: .asciz "Piensa en una letra: "
txt_repetida: .asciz "¡Ya probaste esa, busca otra!\n"
txt_ok: .asciz "¡Acertaste!\n"
txt_fail: .asciz "Uy, fallaste...\n"
txt_gano: .asciz "\n¡Muy bien! La palabra misteriosa es: %s\n"
txt_pierde: .asciz "\nSe acabó el juego... La palabra misteriosa era: %s\n"
txt_salto: .asciz "\n"

letras_previas: .zero 26
entrada_usuario: .space 16
estado_actual: .space 32
formato_letra: .asciz " %c"

.text
.global main

main:
push {lr}
ldr r0, =txt_ingresa_palabra
bl printf
ldr r0, =formato_palabra
ldr r1, =secreta
bl scanf
ldr r0, =secreta
bl calcular_longitud
ldr r1, =long_secreta
str r0, [r1]
bl preparar_juego
ldr r0, =txt_titulo
bl printf
bucle_juego:
bl mostrar_juego
ldr r0, =txt_ingresa
bl printf
ldr r0, =formato_letra
ldr r1, =entrada_usuario
bl scanf
ldr r0, =entrada_usuario
ldrb r0, [r0]
bl evaluar_letra
bl comprobar_final
cmp r0, #0
beq bucle_juego
pop {lr}
bx lr

preparar_juego:
push {r4-r6, lr}
ldr r4, =long_secreta
ldr r4, [r4]
ldr r5, =estado_actual
mov r6, #0
bucle_init:
cmp r6, r4
beq fin_init
mov r0, #'_'
strb r0, [r5, r6]
add r6, r6, #1
b bucle_init
fin_init:
mov r0, #0
strb r0, [r5, r6]
pop {r4-r6, lr}
bx lr

mostrar_juego:
push {lr}
ldr r0, =txt_intentos
ldr r1, =contador_errores
ldr r1, [r1]
ldr r2, =limite_intentos
ldr r2, [r2]
bl printf
ldr r0, =txt_palabra
bl printf
ldr r0, =estado_actual
bl printf
ldr r0, =txt_salto
bl printf
pop {lr}
bx lr

evaluar_letra:
push {r4-r8, lr}
mov r4, r0
cmp r4, #'A'
blt normalizar
cmp r4, #'Z'
bgt normalizar
add r4, r4, #32
normalizar:
cmp r4, #'a'
blt letra_invalida
cmp r4, #'z'
bgt letra_invalida
sub r5, r4, #'a'
ldr r6, =letras_previas
ldrb r7, [r6, r5]
cmp r7, #1
beq letra_usada
mov r7, #1
strb r7, [r6, r5]
ldr r6, =secreta
ldr r7, =estado_actual
mov r8, #0
mov r5, #0
buscar:
ldrb r0, [r6, r8]
cmp r0, #0
beq fin_buscar
mov r1, r0
cmp r0, #'A'
blt skip_norm
cmp r0, #'Z'
bgt skip_norm
add r0, r0, #32
skip_norm:
cmp r0, r4
bne siguiente_letra
strb r1, [r7, r8]
mov r5, #1
siguiente_letra:
add r8, r8, #1
b buscar
fin_buscar:
cmp r5, #1
beq letra_ok
ldr r0, =contador_errores
ldr r1, [r0]
add r1, r1, #1
str r1, [r0]
ldr r0, =txt_fail
bl printf
b letra_invalida
letra_ok:
ldr r0, =contador_aciertos
ldr r1, [r0]
add r1, r1, #1
str r1, [r0]
ldr r0, =txt_ok
bl printf
b letra_invalida
letra_usada:
ldr r0, =txt_repetida
bl printf
letra_invalida:
pop {r4-r8, lr}
bx lr

comprobar_final:
push {r4-r7, lr}
ldr r4, =estado_actual
mov r5, #0
ver_victoria:
ldrb r6, [r4, r5]
cmp r6, #0
beq victoria
cmp r6, #'_'
beq verificar_derrota
add r5, r5, #1
b ver_victoria
victoria:
ldr r0, =txt_gano
ldr r1, =secreta
bl printf
mov r0, #1
b fin_check
verificar_derrota:
ldr r0, =contador_errores
ldr r0, [r0]
ldr r1, =limite_intentos
ldr r1, [r1]
cmp r0, r1
blt seguir_juego
ldr r0, =txt_pierde
ldr r1, =secreta
bl printf
mov r0, #1
b fin_check
seguir_juego:
mov r0, #0
fin_check:
pop {r4-r7, lr}
bx lr

calcular_longitud:
push {r1-r2, lr}
mov r1, r0
mov r2, #0
contar:
ldrb r3, [r1, r2]
cmp r3, #0
beq fin_contar
add r2, r2, #1
b contar
fin_contar:
mov r0, r2
pop {r1-r2, lr}
bx lr

