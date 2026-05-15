.syntax unified
    .global _start

    @ Constantes del juego
    .equ MUNDO, 8            @ Tamano del lado del tablero (8x8)
    .equ CASILLAS, MUNDO*MUNDO @ Total de casillas (64)
    .equ MIS_BARCOS, 5       @ Cantidad de barcos a poner

    .data
    .balign 4             @ Alineacion de memoria obligatoria para ARM

@ --- Textos y Mensajes de la Interfaz ---
txt_titulo:         .asciz "=== BATALLA NAVAL (ARMv6) ===\n"
txt_turno_j1:       .asciz "\n>>> TURNO JUGADOR 1 <<<\n"
txt_turno_j2:       .asciz "\n>>> TURNO JUGADOR 2 <<<\n"
txt_disparar:       .asciz "Donde disparar? (Ej: A1 a H8): "
txt_agua:           .asciz "-> AGUA! No le diste a nada.\n"
txt_tocado:         .asciz "-> TOCADO! Le diste a un barco.\n"
txt_ya_disparado:   .asciz "Ya disparaste ahi antes. Prueba otra.\n"
txt_gana_j1:        .asciz "\n*** FELICIDADES JUGADOR 1 - GANASTE ***\n"
txt_gana_j2:        .asciz "\n*** FELICIDADES JUGADOR 2 - GANASTE ***\n"
txt_error_coord:    .asciz "Coordenada mal escrita. Usa A-H y 1-8.\n"

txt_colocar_j1:     .asciz "\n=== JUGADOR 1: PREPARA TU FLOTA ===\n"
txt_colocar_j2:     .asciz "\n=== JUGADOR 2: PREPARA TU FLOTA ===\n"
txt_instr_flota:    .asciz "Tienes 5 barcos. Ubicalos sin que choquen.\n"
txt_pide_coord:     .asciz "Casilla inicial (Ej: A1): "
txt_pide_ori:       .asciz "Horizontal o Vertical? (h/v): "
txt_error_pone:     .asciz "Error: Se sale del mapa o choca con otro.\n"
txt_cambio_turno:   .asciz "\nPulsa ENTER para limpiar pantalla y cambiar turno..."

@ Nombres de los barcos para ir pidiendo uno a uno
barco_5:            .asciz "Portaaviones (5 casillas)\n"
barco_4:            .asciz "Acorazado (4 casillas)\n"
barco_3a:           .asciz "Crucero A (3 casillas)\n"
barco_3b:           .asciz "Crucero B (3 casillas)\n"
barco_2:            .asciz "Destructor (2 casillas)\n"

@ Arreglos con los datos de los barcos
lista_tam:          .byte 5, 4, 3, 3, 2  @ Tamanos
    .balign 4
lista_nombres:      .word barco_5, barco_4, barco_3a, barco_3b, barco_2

txt_marcador:       .asciz "--- VIDAS RESTANTES ---\n"
txt_vida_j1:        .asciz "J1: "
txt_vida_j2:        .asciz "J2: "

txt_tableros:       .asciz "\nTU FLOTA                 TU RADAR\n"
txt_letras:         .asciz "  A B C D E F G H      A B C D E F G H\n"
txt_sep:            .asciz "    "

@ Secuencia de escape ANSI para limpiar terminal (clear)
txt_limpiar:        .asciz "\033[2J\033[H"
txt_salto:          .asciz "\n"

    .balign 4
@ Memoria reservada para el juego
mapa_j1:            .space CASILLAS      @ Tablero Jugador 1
mapa_j2:            .space CASILLAS      @ Tablero Jugador 2

vidas_j1:           .word 0              @ Contador de casillas vivas J1
vidas_j2:           .word 0              @ Contador de casillas vivas J2

buffer_teclado:     .space 32    @ Espacio para leer lo que escribe el usuario
modo_colocacion:    .byte 0      @ 1 durante fase de poner barcos, 0 durante batalla

@ Simbolos del mapa
sim_mar:            .asciz "~ "
sim_barco:          .asciz "B "
sim_fallo:          .asciz "o "   @ Minuscula para diferenciar mejor
sim_fuego:          .asciz "X "

    .text
    .balign 4

_start:
    bl principal
    mov r0, #0
    mov r7, #1          @ Syscall exit
    swi 0

@ --- Funcion Principal (Main) ---
principal:
    @ Guardamos registros importantes (R4-R11 son callee-saved)
    @ Push par de registros para mantener stack alineado a 8 bytes
    push {r4-r11, r12, lr}
    
    bl limpiar_mapas    @ Poner ceros en los tableros

    @ -- FASE 1: Colocar barcos J1 --
    mov r4, #1          @ R4 indica de quien es el turno (1=J1)
    bl poner_barcos
    bl esperar_enter

    @ -- FASE 2: Colocar barcos J2 --
    mov r4, #2          @ Turno J2
    bl poner_barcos
    bl esperar_enter

    @ -- FASE 3: Batalla --
    mov r4, #1          @ Empieza J1

bucle_juego:
    bl cls              @ Limpiar pantalla
    
    @ Mostrar de quien es el turno
    cmp r4, #1
    beq es_turno_j1
    ldr r0, =txt_turno_j2
    b most_turno
es_turno_j1:
    ldr r0, =txt_turno_j1
most_turno:
    bl imprimir
    bl mostrar_vidas
    bl dibujar_mapas    @ Muestra los dos tableros del jugador actual

pedir_tiro:
    ldr r0, =txt_disparar
    bl imprimir
    
    bl leer_coord       @ Devuelve indice 0-63 en R0
    cmp r0, #-1
    beq tiro_invalido

    mov r1, r0          @ Mover indice a R1
    bl procesar_disparo @ Realizar el tiro
    cmp r0, #2          @ Si retorna 2, es que ya disparo ahi
    beq pedir_tiro
    
    b revisar_ganador   @ Ver si alguien gano

tiro_invalido:
    ldr r0, =txt_error_coord
    bl imprimir
    b pedir_tiro

revisar_ganador:
    @ Si jugaba J1, miramos si J2 se quedo sin vidas
    cmp r4, #1
    beq check_j2_muerto
    
    @ Revisa vidas J1 (si jugaba J2)
    ldr r0, =vidas_j1
    ldr r0, [r0]
    cmp r0, #0
    beq gano_j2
    b cambiar_turno

check_j2_muerto:
    ldr r0, =vidas_j2
    ldr r0, [r0]
    cmp r0, #0
    beq gano_j1
    b cambiar_turno

cambiar_turno:
    bl esperar_enter
    @ Alternar R4 entre 1 y 2
    cmp r4, #1
    moveq r4, #2
    movne r4, #1
    b bucle_juego

gano_j1:
    bl cls
    ldr r0, =txt_gana_j1
    bl imprimir
    b fin_juego

gano_j2:
    bl cls
    ldr r0, =txt_gana_j2
    bl imprimir

fin_juego:
    pop {r4-r11, r12, lr}
    bx lr

@ --- Subrutina para colocar barcos ---
@ R4 tiene el jugador actual
poner_barcos:
    push {r4, r5-r10, lr} 
    ldr r0, =modo_colocacion
    mov r1, #1
    strb r1, [r0]
    mov r5, #0                  @ Contador de barcos puestos (0 a 4)
    ldr r6, =lista_tam          @ Puntero a tamanos
    ldr r7, =lista_nombres      @ Puntero a nombres

bucle_poner:
    cmp r5, #MIS_BARCOS
    beq fin_poner

    bl cls
    @ Titulo segun jugador
    cmp r4, #1
    beq tit_pb_j1
    ldr r0, =txt_colocar_j2
    b tit_pb_comun
tit_pb_j1:
    ldr r0, =txt_colocar_j1
tit_pb_comun:
    bl imprimir
    ldr r0, =txt_instr_flota
    bl imprimir
    
    bl dibujar_mapas            @ Para ver donde vamos poniendo

    @ Decir "Barco X"
    ldr r8, [r7, r5, lsl #2]    @ Cargar string nombre
    mov r0, r8
    bl imprimir

    @ 1. Pedir Coordenada
preg_c:
    ldr r0, =txt_pide_coord
    bl imprimir
    bl leer_coord
    cmp r0, #-1
    beq error_c
    mov r9, r0                  @ Guardar indice (0-63) en R9

    @ 2. Pedir Orientacion
    ldr r0, =txt_pide_ori
    bl imprimir
    bl leer_caracter            @ Lee 1 letra
    
    @ Mirar si es h o v
    cmp r0, #'h'
    beq es_horiz
    cmp r0, #'v'
    beq es_vert
    b error_c                   @ Si no es h ni v, error

es_horiz:
    mov r10, #0                 @ 0 = Horizontal
    b intentar_poner
es_vert:
    mov r10, #1                 @ 1 = Vertical
    b intentar_poner

error_c:
    ldr r0, =txt_error_coord
    bl imprimir
    b preg_c

intentar_poner:
    ldrb r1, [r6, r5]           @ Cargar tamano del barco actual
    mov r2, r9                  @ Posicion
    mov r3, r10                 @ Orientacion
    
    bl colocar_logica           @ Intentar ponerlo en memoria
    cmp r0, #0                  @ 0 = Exito
    beq siguiente_barco

    @ Fallo
    ldr r0, =txt_error_pone
    bl imprimir
    @ Pausa para leer error
    ldr r0, =buffer_teclado
    mov r1, #2
    bl leer_seguro
    b bucle_poner               @ Repetir el mismo barco

siguiente_barco:
    add r5, r5, #1              @ Siguiente barco
    b bucle_poner

fin_poner:
    ldr r0, =modo_colocacion
    mov r1, #0
    strb r1, [r0]
    pop {r4, r5-r10, lr}
    bx lr

@ --- Logica para validar y escribir el barco en RAM ---
@ Params: R1=tamano, R2=indice, R3=orientacion
@ Retorna: R0=0 (Bien), R0=1 (Mal)
colocar_logica:
    push {r4-r11, r12, lr}
    mov r11, #MUNDO             @ Ancho 8

    mov r10, r1                 @ R10 guarda tamano
    mov r12, r3                 @ Guardar orientacion antes de division_mod
    mov r0, r2                  @ R0 posicion
    mov r1, #MUNDO              @ Divisor 8 para saber fila
    
    bl division_mod             @ R0=Fila, R1=Columna
    mov r5, r0                  @ Fila inicial
    mov r6, r1                  @ Columna inicial

    @ Apuntar al tablero correcto
    cmp r4, #1
    beq sel_tab_j1
    ldr r8, =mapa_j2
    ldr r9, =vidas_j2
    b tab_sel_ok
sel_tab_j1:
    ldr r8, =mapa_j1
    ldr r9, =vidas_j1
tab_sel_ok:
    mov r4, r12                 @ Recuperar orientacion (0=h, 1=v)

    @ Paso 1: Verificar si cabe y si esta libre
    mov r7, #0                  @ i = 0
bucle_check:
    cmp r7, r10                 @ i < tamano
    beq escribir_barco          @ Si chequeamos todo bien, vamos a escribir

    @ Calcular donde cae esta parte del barco
    mov r12, r5                 @ Fila temporal
    mov r14, r6                 @ Col temporal

    cmp r4, #0                  @ Es horizontal?
    beq calc_h
    add r12, r12, r7            @ Vertical: Fila + i
    b check_lim
calc_h:
    add r14, r14, r7            @ Horizontal: Col + i

check_lim:
    @ Mirar si se sale del tablero (0-7)
    cmp r12, #7
    bgt ret_fail
    cmp r14, #7
    bgt ret_fail

    @ Mirar que hay en esa casilla
    mul r0, r12, r11            @ Fila * 8
    add r0, r0, r14             @ + Columna
    ldrb r1, [r8, r0]           @ Leer byte del mapa
    cmp r1, #0                  @ 0 = Agua limpia
    bne ret_fail                @ Si no es 0, choca

    add r7, r7, #1
    b bucle_check

escribir_barco:
    @ Paso 2: Escribir los 1s en el mapa
    mov r7, #0
bucle_write:
    cmp r7, r10
    beq ret_success

    mov r12, r5 
    mov r14, r6
    cmp r4, #0
    beq write_h
    add r12, r12, r7
    b write_cell
write_h:
    add r14, r14, r7

write_cell:
    mul r0, r12, r11
    add r0, r0, r14
    mov r1, #1
    strb r1, [r8, r0]           @ Poner un 1 (Barco)
    
    @ Sumar 1 a las vidas totales
    ldr r1, [r9]
    add r1, r1, #1
    str r1, [r9]

    add r7, r7, #1
    b bucle_write

ret_success:
    mov r0, #0
    pop {r4-r11, r12, lr}
    bx lr

ret_fail:
    mov r0, #1
    pop {r4-r11, r12, lr}
    bx lr

@ --- Funcion para leer coord estilo "A5" ---
leer_coord:
    push {r4, lr}
    
    ldr r0, =buffer_teclado
    mov r1, #8                  @ Leer max 8 chars
    bl leer_seguro
    
    @ Analizar buffer
    ldr r1, =buffer_teclado
    ldrb r2, [r1]               @ Letra (Columna)
    ldrb r3, [r1, #1]           @ Numero (Fila)

    @ Pasar letra a mayuscula si es minuscula
    cmp r2, #'a'
    blt ya_mayus
    cmp r2, #'z'
    bgt ya_mayus
    sub r2, r2, #32
ya_mayus:
    sub r2, r2, #'A'          @ A=0, B=1...
    
    sub r3, r3, #'1'          @ '1'=0, '2'=1...

    @ Validar rangos (0 a 7)
    cmp r2, #0
    blt coord_mala
    cmp r2, #7
    bgt coord_mala
    cmp r3, #0
    blt coord_mala
    cmp r3, #7
    bgt coord_mala

    @ Calcular indice lineal = Fila * 8 + Columna
    mov r4, #MUNDO
    mul r0, r3, r4
    add r0, r0, r2
    
    pop {r4, lr}
    bx lr

coord_mala:
    mov r0, #-1
    pop {r4, lr}
    bx lr

@ --- Funcion simple para leer 1 caracter ---
leer_caracter:
    push {r4, lr}
    ldr r0, =buffer_teclado
    mov r1, #4
    bl leer_seguro
    ldr r1, =buffer_teclado
    ldrb r0, [r1]
    
    @ Convertir a minuscula para facilitar comparacion
    cmp r0, #'A'
    blt fin_lc
    cmp r0, #'Z'
    bgt fin_lc
    add r0, r0, #32             @ De mayus a minus
fin_lc:
    pop {r4, lr}
    bx lr

@ --- Lectura de teclado robusta (Syscall Read) ---
leer_seguro:
    push {r4-r8, lr}        
    mov r4, r0              @ Puntero buffer
    mov r5, r1              @ Tamano max

    @ Limpiar buffer antes de leer
    mov r2, #0
limpia_buf:
    cmp r2, r5
    beq inicia_lectura
    add r3, r4, r2
    mov r0, #0
    strb r0, [r3]
    add r2, r2, #1
    b limpia_buf

inicia_lectura:
    mov r6, #0              @ Bytes leidos
bucle_leer:
    mov r0, #0              @ stdin (0)
    add r1, r4, r6          @ Donde escribir
    mov r2, #1              @ Leer de a 1 byte
    mov r7, #3              @ sys_read
    swi 0

    cmp r0, #1              @ Leimos algo?
    bne fin_lectura

    ldrb r2, [r1]           @ Mirar que leimos
    cmp r2, #'\n'           @ Es Enter?
    beq es_enter

    @ Si no es enter y cabe, seguimos
    cmp r6, r5
    bge bucle_leer          @ Si lleno, ignorar extras
    
    add r6, r6, #1
    b bucle_leer

es_enter:
    @ Ponemos null terminator en vez del enter
    add r1, r4, r6
    mov r0, #0
    strb r0, [r1]

fin_lectura:
    pop {r4-r8, lr}
    bx lr

@ --- Utilidades de Pantalla ---
cls:
    push {r1, lr}
    ldr r0, =txt_limpiar
    bl imprimir
    pop {r1, lr}
    bx lr

@ Imprime cadena terminada en 0 apuntada por R0
imprimir:
    push {r1-r3, r6, r7, lr}  
    mov r1, r0
    mov r2, #0
cuenta_chars:
    ldrb r3, [r1, r2]
    cmp r3, #0
    beq imprime_ya
    add r2, r2, #1
    b cuenta_chars
imprime_ya:
    mov r1, r0            @ Buffer
    mov r0, #1            @ stdout
    mov r7, #4            @ sys_write
    swi 0
    pop {r1-r3, r6, r7, lr}
    bx lr

esperar_enter:
    push {r1, lr}
    ldr r0, =txt_cambio_turno
    bl imprimir
    ldr r0, =buffer_teclado
    mov r1, #8
    bl leer_seguro
    pop {r1, lr}
    bx lr

limpiar_mapas:
    push {r4-r6, lr}
    ldr r4, =mapa_j1
    mov r5, #CASILLAS
    mov r6, #0
borra_1:
    cmp r5, #0
    beq borra_2_init
    strb r6, [r4], #1
    sub r5, r5, #1
    b borra_1
borra_2_init:
    ldr r4, =mapa_j2
    mov r5, #CASILLAS
borra_2:
    cmp r5, #0
    beq fin_borra
    strb r6, [r4], #1
    sub r5, r5, #1
    b borra_2
fin_borra:
    mov r6, #0
    ldr r4, =vidas_j1
    str r6, [r4]
    ldr r4, =vidas_j2
    str r6, [r4]
    pop {r4-r6, lr}
    bx lr

mostrar_vidas:
    push {r1, lr}
    ldr r0, =txt_marcador
    bl imprimir
    
    ldr r0, =txt_vida_j1
    bl imprimir
    ldr r1, =vidas_j1
    ldr r0, [r1]
    bl print_num        @ Imprimir numero decimal
    ldr r0, =txt_salto
    bl imprimir
    
    ldr r0, =txt_vida_j2
    bl imprimir
    ldr r1, =vidas_j2
    ldr r0, [r1]
    bl print_num
    ldr r0, =txt_salto
    bl imprimir
    pop {r1, lr}
    bx lr

@ Convierte R0 a ASCII y lo imprime
print_num:
    push {r0-r8, lr}
    sub sp, sp, #16     @ Buffer local
    mov r6, sp 
    mov r7, #0
    cmp r0, #0
    bne pn_no_cero
    mov r1, #'0'
    strb r1, [r6, r7]
    add r7, r7, #1
    b pn_imprimir
pn_no_cero:
    mov r1, r0
    mov r2, #0
pn_div:
    cmp r1, #10
    blt pn_digito
    sub r1, r1, #10     @ Restas sucesivas en vez de div
    add r2, r2, #1
    b pn_div
pn_digito:
    add r1, r1, #'0'
    strb r1, [r6, r7]
    add r7, r7, #1
    mov r0, r2
    cmp r0, #0
    bne pn_no_cero
pn_imprimir:
    sub r7, r7, #1      @ Imprimir revertido
pn_loop:
    ldrb r0, [r6, r7]
    bl put_char
    cmp r7, #0
    beq pn_fin
    sub r7, r7, #1
    b pn_loop
pn_fin:
    add sp, sp, #16
    pop {r0-r8, lr}
    bx lr

put_char:
    push {r0-r3, r7, lr}
    sub sp, sp, #8
    strb r0, [sp]
    mov r0, #1
    mov r1, sp
    mov r2, #1
    mov r7, #4
    swi 0
    add sp, sp, #8
    pop {r0-r3, r7, lr}
    bx lr

dibujar_mapas:
    push {r4-r11, r12, lr}
    mov r12, #MUNDO
    ldr r6, =modo_colocacion
    ldrb r6, [r6]

    @ Configurar punteros segun turno
    cmp r4, #1
    beq dm_j1
    ldr r8, =mapa_j2    @ Mi mapa
    ldr r9, =mapa_j1    @ Mapa enemigo
    b dm_sel
dm_j1:
    ldr r8, =mapa_j1
    ldr r9, =mapa_j2
dm_sel:
    ldr r0, =txt_tableros
    bl imprimir
    ldr r0, =txt_letras
    bl imprimir

    mov r10, #0               @ Fila actual (0-7)
fila_loop:
    cmp r10, #MUNDO
    beq dm_salir

    @ Numero de linea
    mov r0, #'1'
    add r0, r0, r10
    bl put_char
    mov r0, #' '
    bl put_char

    @ --- MI TABLERO (Izquierda) ---
    mov r11, #0
col_propia:
    cmp r11, #MUNDO
    beq pintar_separador
    mul r1, r10, r12
    add r1, r1, r11
    add r1, r8, r1
    ldrb r0, [r1]
    
    @ En batalla (modo_colocacion=0) ocultamos barcos intactos (1) como agua.
    @ En colocacion (modo_colocacion=1) si mostramos los barcos para poder ubicarlos.
    cmp r0, #0
    beq p_agua
    cmp r0, #1
    beq p_barco_o_mar
    cmp r0, #2
    beq p_fallo
    /* cmp r0, #3 */
    b p_fuego

p_barco_o_mar:
    cmp r6, #1
    beq p_barco
    b p_agua

p_agua:  ldr r0, =sim_mar 
         b imp_celda
p_barco: ldr r0, =sim_barco
         b imp_celda
p_fallo: ldr r0, =sim_fallo
         b imp_celda
p_fuego: ldr r0, =sim_fuego
         b imp_celda
imp_celda: 
    bl imprimir
    add r11, r11, #1
    b col_propia

pintar_separador:
    ldr r0, =txt_sep
    bl imprimir
    mov r0, #'1'
    add r0, r0, r10
    bl put_char
    mov r0, #' '
    bl put_char

    @ --- TABLERO RIVAL (Derecha - Radar) ---
    mov r11, #0
col_rival:
    cmp r11, #MUNDO
    beq sig_fila
    mul r1, r10, r12
    add r1, r1, r11
    add r1, r9, r1
    ldrb r0, [r1]
    
    @ Aqui ocultamos barcos (1 se ve como agua)
    cmp r0, #2
    beq r_fallo
    cmp r0, #3
    beq r_fuego
    ldr r0, =sim_mar     @ 0 y 1 se ven igual
    b r_imp
r_fallo: ldr r0, =sim_fallo
         b r_imp
r_fuego: ldr r0, =sim_fuego
         b r_imp
r_imp: bl imprimir
    add r11, r11, #1
    b col_rival

sig_fila:
    ldr r0, =txt_salto
    bl imprimir
    add r10, r10, #1
    b fila_loop

dm_salir:
    pop {r4-r11, r12, lr}
    bx lr

@ --- Logica de Disparo ---
procesar_disparo:
    push {r4-r11, r12, lr}
    mov r11, #MUNDO

    @ R1 tiene indice del disparo
    
    cmp r4, #1
    beq disp_j1
    ldr r8, =mapa_j1    @ J2 dispara a J1
    ldr r7, =vidas_j1
    b sel_objetivo
disp_j1:
    ldr r8, =mapa_j2    @ J1 dispara a J2
    ldr r7, =vidas_j2
sel_objetivo:

    ldrb r2, [r8, r1]   @ Ver que hay ahi
    
    @ Estados: 0,1,2,3
    cmp r2, #2
    beq ya_estaba
    cmp r2, #3
    beq ya_estaba
    
    cmp r2, #1
    beq es_tocado
    
    @ Fallo (Agua)
    mov r3, #2
    strb r3, [r8, r1]
    ldr r0, =txt_agua
    bl imprimir
    mov r0, #0
    pop {r4-r11, r12, lr}
    bx lr

es_tocado:
    mov r3, #3
    strb r3, [r8, r1]
    
    @ Restar vida
    ldr r3, [r7]
    sub r3, r3, #1
    str r3, [r7]

    ldr r0, =txt_tocado
    bl imprimir
    mov r0, #1
    pop {r4-r11, r12, lr}
    bx lr

ya_estaba:
    ldr r0, =txt_ya_disparado
    bl imprimir
    mov r0, #2
    pop {r4-r11, r12, lr}
    bx lr

@ Division manual para no depender de hardware
@ R0 / R1 -> Cociente R0, Residuo R1
division_mod:
    push {r4, lr}
    mov r2, #0
div_loop:
    cmp r0, r1
    blt div_fin
    sub r0, r0, r1
    add r2, r2, #1
    b div_loop
div_fin:
    mov r3, r0              @ Residuo temporal
    mov r0, r2              @ Cociente final
    mov r1, r3              @ Residuo final
    pop {r4, lr}
    bx lr
