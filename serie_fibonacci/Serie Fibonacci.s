.DATA
    .ALIGN 4 		        @ Alineación de datos en memoria (múltiplos de 4)
Numero:    .WORD   20       @ Número de término de Fibonacci deseado (N)
Resultado: .SPACE 4         @ Espacio reservado para almacenar Fibonacci(Numero)

.TEXT
    .ALIGN 4                @ Asegura la alineación del código en memoria
Principal:
        LDR     R0, =Numero        @ Cargar la dirección de memoria donde está almacenado Numero
        LDR     R0, [R0]           @ Cargar el valor de Numero en el registro R0
        LDR     R5, =Resultado     @ Cargar la dirección de memoria donde se almacenará el resultado

        CMP     R0, #1             @ Comparar Numero con 1
        BLE     almacenar_directo  @ Si Numero <= 1, saltar a almacenar_directo para guardarlo directamente

        MOV     R1, #0             @ Inicializar F(0) = 0 en R1
        MOV     R2, #1             @ Inicializar F(1) = 1 en R2

bucle:
        SUB     R0, R0, #1         @ Restar 1 a Numero (N--)
        CMP     R0, #0             @ Comparar Numero con 0 para verificar si hemos terminado
        BEQ     almacenar_resultado @ Si Numero == 0, saltar a almacenar_resultado para guardar el resultado final

        ADD     R3, R1, R2         @ Calcular el siguiente término de Fibonacci: F(i) = F(i-1) + F(i-2)
        MOV     R1, R2             @ Mover el valor de F(i-1) a F(i-2) (desplazamiento hacia adelante)
        MOV     R2, R3             @ Mover el valor de F(i) a F(i-1) (desplazamiento hacia adelante)
        B       bucle              @ Volver a la etiqueta 'bucle' para continuar el cálculo

almacenar_directo:
        STR     R0, [R5]           @ Si Numero es 0 o 1, almacenarlo directamente en la dirección Resultado
        B       fin                @ Saltar a fin para terminar la ejecución

almacenar_resultado:
        STR     R2, [R5]           @ Almacenar el valor calculado de F(Numero) en memoria

fin:
        WFI                        @ Finalizar la ejecución y esperar interrupción (modo de bajo consumo)
