*-----------------------------------------------------------
* Title      : PRAREC25
* Description: Emulador de la BUIBEX-X
*-----------------------------------------------------------
    ORG $1000
EMEM:   DC.W $002A,$0003,$000C,$4021,$4C10,$5804,$4005
        DC.W $201D,$900A,$A00B,$500C,$0FFA,$900F,$080C
        DC.W $A005,$C000,$0000,$0001,$0000,$0000,$0001
EIR:    DC.W 0 ;eregistro de instruccion
EPC:    DC.W 0 ;econtador de programa
ET0:    DC.W 0 ;eregistro T0
ET1:    DC.W 0 ;eregistro T1
ER2:    DC.W 0 ;eregistro R2
ER3:    DC.W 0 ;eregistro R3
ER4:    DC.W 0 ;eregistro R4
ER5:    DC.W 0 ;eregistro R5
ESR:    DC.W 0 ;eregistro de estado (00000000 00000NCZ)

START:
    CLR.W EPC

FETCH:
    ;--- IFETCH: INICIO FETCH
        ;*** En esta seccion debeis introducir el codigo necesario para cargar
        ;*** en EIR la siguiente instruccion a ejecutar, indicada por el EPC,
	    ;*** y dejar listo el EPC para que apunte a la siguiente instruccion
	
	        ; ESCRIBID VUESTRO CODIGO AQUI

        LEA EMEM, A0   ; A0 apunta al inicio de la memoria del programa (EMEM)
        MOVE.W EPC, D0 ; Copia EPC a D0 (posición actual)
        MULS #2, D0    ; Multiplica por 2 (cada instrucción ocupa 2 bytes)
        ADD.W D0, A0   ; Suma el offset para apuntar a la instrucción correcta
        MOVE.W (A0), D1 ; Carga en D1 la instrucción leída desde memoria
        ADDQ #1, EPC   ; Incrementa EPC para apuntar a la siguiente instrucción
        MOVE.W D1, EIR ; Guarda la instrucción en el registro EIR
	    
        
    ;--- FFETCH: FIN FETCH
    
    
    
    ;--- IBRDECOD: INICIO SALTO A DECOD
        ;*** En esta seccion debeis preparar la pila para llamar a la subrutina
        ;*** DECOD, llamar a la subrutina, y vaciar la pila correctamente,
        ;*** almacenando el resultado de la decodificacion en D1

    	    ; ESCRIBID VUESTRO CODIGO AQUI    	
        SUBQ #2, A7              ; Reserva espacio en la pila
        MOVE.W D1, -(A7)         ; Mete la instrucción en la pila
        JSR DECOD  ; Llama a la subrutina DECOD para decodificar la instrucción
        ADDQ #2, A7              ; Libera espacio de la pila
        MOVE.W (A7)+, D1  ; Recupera el valor de retorno (tipo de instrucción)
    
        
    ;--- FBRDECOD: FIN SALTO A DECOD
    
    
    
    ;--- IBREXEC: INICIO SALTO A FASE DE EJECUCION
        ;*** Esta seccion se usa para saltar a la fase de ejecucion
        ;*** NO HACE FALTA MODIFICARLA
    MULU #6,D1
    MOVEA.L D1,A1
    JMP JMPLIST(A1)
JMPLIST:
    JMP ESET
    JMP EINC
    JMP EADD
    JMP ESUB
    JMP ECMP
    JMP EAND
    JMP EOR
    JMP ENOT
    JMP ETRA
    JMP ELEA
    JMP ESTI
    JMP ELDI
    JMP ESTO
    JMP ELOA
    JMP EJMN
    JMP EJMZ
    JMP EJMI
    JMP EHLT
    ;--- FBREXEC: FIN SALTO A FASE DE EJECUCION
    
    
    
    ;--- IEXEC: INICIO EJECUCION
        ;*** En esta seccion debeis implementar la ejecucion de cada einstr.
	
	; ESCRIBID EN CADA ETIQUETA LA FASE DE EJECUCION DE CADA INSTRUCCION
ESET:                            ; Carga inmediato con signo a Ra
        JSR CODIFICAR_B          ; Aunque sea A son los 3 menos significativos
        MOVE.W EIR, D2           ; Carga instrucción en D2
        ANDI.W #$07F8, D2        ; Extraemos c
        LSR #3, D2               ; Desplaza bits a la derecha para alinearlos
        EXT.W D2                 ; Extiende signo de byte a word
        MOVE.W D2, (A1)          ; Poner c en Ra
        JSR ACTUALITZA_ZN_FLAGS
        JMP Fin_Ejecucion

EINC:                            ; Incrementa Ra con valor inmediato
        JSR CODIFICAR_B          ; Aunque sea A son los 3 menos significativos
        MOVE.W (A1),D1           ; Mover a D1 Rb
        MOVE.W D1, D3            ; Guarda copia original para comparar despues
        MOVE.W EIR, D2           ; Carga instrucción en D2
        LSR.W #3, D2             ; Alinea bits a la derecha
        ANDI.W #$00FF, D2        ; Extraemos c
        EXT.W D2                 ; Extiende signo de byte a word
        ADD.W D1,D2              ; Ra + c
        MOVE.W D2, (A1)          ; Poner Ra+c en Ra
        JSR ACTUALITZA_TOTS_FLAGS
        JMP Fin_Ejecucion

EADD:                            ; Suma Ra+Rb
        JSR CODIFICAR_A
        JSR CODIFICAR_B
        MOVE.W (A0), D3          ; Lee valor del registro origen D3=Ra
        MOVE.W (A1), D2          ; Mueve Rb a D2
        ADD.W D3, D2             ;Suma los componentes
        MOVE.W D2, (A1)          ; Escribe valor en destino
        JSR ACTUALITZA_TOTS_FLAGS
        JMP Fin_Ejecucion

ESUB:                            ; Resta A + (B' + 1) 
        JSR CODIFICAR_A
        JSR CODIFICAR_B
        MOVE.W (A0), D3          ; Lee valor del registro origen D3=Ra
        MOVE.W (A1), D2          ; Mueve Rb a D2
        NOT D3                   ;Nega D3(Ra)
        ADDQ.B #1, D3            ; Suma 1 a D3
        ADD.W D3, D2             ;Suma los componentes
        MOVE.W D2, (A1)          ; Escribe valor en destino
        JSR ACTUALITZA_TOTS_FLAGS
        JMP Fin_Ejecucion

ECMP:                            ; Compara Ra - Rb sin guardar resultado 
        JSR CODIFICAR_A
        JSR CODIFICAR_B
        MOVE.W (A1), D3          ; Mueve Rb a D3
        MOVE.W (A0), D2          ; Mueve Ra a D2
        SUB.W D3, D2             ; Resta Rb-Ra
        JSR ACTUALITZA_TOTS_FLAGS
        JMP Fin_Ejecucion

EAND:                            ; Operación AND entre Ra y Rb -> Rb
        JSR CODIFICAR_A
        JSR CODIFICAR_B
        MOVE.W (A1),D2           ; Rb a D2
        MOVE.W (A0),D3           ; Ra a D3
        AND.W D3, D2             ; D2 = D2 AND D3
        MOVE.W D2, (A1)          ; Rb = resultado
        JSR ACTUALITZA_ZN_FLAGS
        JMP Fin_Ejecucion

EOR:
        JSR CODIFICAR_A
        JSR CODIFICAR_B
        MOVE.W (A1),D2           ; Rb a D2
        MOVE.W (A0),D3           ; Ra a D3
        OR.W D3, D2              ; D2 = D2 OR D3
        MOVE.W D2, (A1)          ; Rb = resultado
        JSR ACTUALITZA_ZN_FLAGS
        JMP Fin_Ejecucion

ENOT:
        JSR CODIFICAR_B
        MOVE.W (A1),D2           ; Rb a D2
        NOT.W D2                 ; NOT bit a bit
        MOVE.W D2,(A1)           ; Rb = resultado
        JSR ACTUALITZA_ZN_FLAGS
        JMP Fin_Ejecucion
ETRA:                            ; Transferencia de contenido entre registros 
        JSR CODIFICAR_A
        JSR CODIFICAR_B
        MOVE.W (A0),D2           ; Mover Ra a D2
        MOVE.W D2, (A1)          ; Escribe valor en destino
        JMP Fin_Ejecucion

ELEA:
        MOVE.W EIR, D7           ; Carga instrucción en D7
        ANDI.W #$0700, D7        ; Extrae bits (bbb)
        LSR #8, D7
        CMP #0, D7
        BEQ CODIF_ET0
        CMP #1, D7
        BEQ CODIF_ET1
        CMP #2, D7
        BEQ CODIF_ER2
        CMP #3, D7
        BEQ CODIF_ER3
        CMP #4, D7
        BEQ CODIF_ER4
        CMP #5, D7
        BEQ CODIF_ER5
CODIF_ET0: 
    LEA ET0, A1
    BRA Final_codif
    
CODIF_ET1: 
    LEA ET1, A1
    BRA Final_codif
    
CODIF_ER2: 
    LEA ER2, A1
    BRA Final_codif
    
CODIF_ER3: 
    LEA ER3, A1
    BRA Final_codif
    
CODIF_ER4: 
    LEA ER4, A1
    BRA Final_codif
    
CODIF_ER5: 
    LEA ER5, A1
    BRA Final_codif
Final_codif:
        MOVE.W EIR, D2
        ANDI.W #$00FF, D2       ; Extrae campo m
        MOVE.W D2, (A1)         ; Rb = dirección m
        JMP Fin_Ejecucion

ESTI:
        JSR CODIFICAR_B         ; Rb=A1 (conté la direcció indirecta)
        MOVE.W (A1), D2         ; D2 = contingut de Rb (adreça intermèdia)
        MULU #2, D2             ; Convertim a offset de paraula
        LEA EMEM, A2            ; Carregam base de la memòria en A2
        ADD.W D2, A2            ; A2 apunta a la posició EMEM[D2]
        MOVE.W EIR, D4
        ANDI.W #$0008, D4       ; Bit j  decideix si ET0 o ET1
        BEQ STI_ET0             ; Si j = 0  ET0
        MOVE.W ET1, (A2)        ; Guarda ET1 a EMEM[valor de Rb]
        JMP Fin_Ejecucion

STI_ET0:
        MOVE.W ET0, (A2)        ; Guarda ET0 a EMEM[valor de Rb]
        JMP Fin_Ejecucion
        
ELDI:
        JSR CODIFICAR_B         ; Ra a A0
        MOVE.W (A1),D2          ; Carga dirección intermedia
        MULU #2, D2             ; Multiplica por 2 (word)
        LEA EMEM, A2
        ADD.W D2, A2            ; Calcula [[Ra]]
        MOVE.W (A2),D3          ; D3 = [[Ra]]
        MOVE.W D3, D2           ; Para actualizar los flags después
        MOVE.W EIR, D4
        ANDI.W #0008, D4
        BEQ LDI_ET0
        MOVE.W D3, ET1
        JSR ACTUALITZA_ZN_FLAGS
        JMP Fin_Ejecucion
LDI_ET0:
        MOVE.W D3, ET0
        JSR ACTUALITZA_ZN_FLAGS
        JMP Fin_Ejecucion
ESTO:                            ; Etiqueta para almacenar valor ETj en memoria
        CLR.W D2
        MOVE.W EIR, D3           
        MOVE.B D3,D2             ; Extrae campo dirección a D2
        MULU #2,D2
        LEA EMEM, A2             ;Carga la dirección base de memoria EMEM en A2
        ADD.W D2, A2             ; Calcula la dirección final 
        BTST #9 , EIR            ; Comprueba bit para decidir entre ET0 y ET1
        BEQ STO_ET0              ; Si bit 9 = 0, usa ET0
        MOVE.W ET1, (A2)         ; Guarda contenido de ET1 en la dirección
        JMP Fin_Ejecucion        ; Termina ejecución
STO_ET0:
        MOVE.W ET0, (A2)         ; Guarda contenido de ET0 en la dirección
        JMP Fin_Ejecucion        ; Termina ejecución
ELOA:                            ; Etiqueta para cargar dato de memoria a Ej
        CLR.W D3
        MOVE.W EIR, D2           
        MOVE.B D2, D3            ; Extrae solo la m a D3
        MULU #2,D3
        LEA EMEM, A2             ; Dirección base de memoria a A2
        ADD.W D3, A2             ; Calcula dirección final
        MOVE.W (A2), D2
        BTST #9, EIR             ; Revisa bit 9 para elegir registro destino
        BEQ LOA_ET0              ; Si bit 9 = 0, carga en ET0
        MOVE.W D2, ET1           ; Carga valor de memoria en ET1
        JSR ACTUALITZA_ZN_FLAGS
        JMP Fin_Ejecucion
LOA_ET0:
        MOVE.W D2, ET0           ; Carga valor en ET0
        JSR ACTUALITZA_ZN_FLAGS
        JMP Fin_Ejecucion

EJMN:                            ; Salto condicional si el flag N está activo
        MOVE.W EIR, D2           ; Copia instrucción a D2
        MOVE.B D2, D3            ; Extrae campo dirección a D3
        BTST #1, ESR             ; Comprueba la N del registro de estado ESR
        BEQ Fin_Ejecucion        ; Si N no está activo, no salta
        MOVE.W D3, EPC           ; Si N está activo, carga EPC con m
        JMP Fin_Ejecucion        ; Finaliza ejecución
EJMZ:                            ; Salto condicional si el flag Z está activo
        MOVE.W EIR, D2           ; Copia la instrucción a D2
        MOVE.B D2, D3            ; Extrae el campo dirección 'm' a D3
        MOVE.W ESR, D5
        BTST #2, D5             ; Comprueba la Z del registro de estado ESR
        BEQ Fin_Ejecucion        ; Si el bit Z no está activado, no salta
        MOVE.W D3, EPC           ; Carga el contador de programa EPC con m
        JMP Fin_Ejecucion        ; Finaliza la ejecución de la instrucción
EJMI:                            ; Etiqueta para salto incondicional (Jump)
        CLR.W D3
        MOVE.W EIR, D2           ; Copia el contenido de EIR al registro D2
        MOVE.B D2, D3            ; Extrae solo m a D3
        MOVE.W D3, EPC           ; Carga el EPC con esa dirección para saltar
        JMP Fin_Ejecucion        ; Salta para finalizar la instrucción
EHLT:                    ;Etiqueta para la instrucción HALT (detener ejecución)
        JMP Fin_Programa ; Salta a la etiqueta Fin_Programa para terminar

Fin_Ejecucion:
    JMP FETCH
    ;--- FEXEC: FIN EJECUCION
    
    

    ;--- ISUBR: INICIO SUBRUTINAS
        ;*** Aqui debeis incluir las subrutinas que necesite vuestra solucion
        ;*** SALVO DECOD, que va en la siguiente seccion

	        ; ESCRIBID VUESTRO CODIGO AQUI
	        
ACTUALITZA_TOTS_FLAGS:
        CLR.W ESR            ; Esborra els flags
        TST.W D2             ; Mira si D2 és zero flag Z
        BEQ Setz
        BMI Setn             ; Mira si D2 és negatiu (flag N) 
        BRA Carry            ; Si no és Z ni N, salta directament al carry

Setz:
        ORI #$0004, ESR
        BRA Carry

Setn:
        ORI #$0002, ESR
        ; Continua per mirar el carry també

Carry:
        CMP.W D3, D2         ; Si D2 < D3 ? desbordament ? Carry
        BLO Setc
        RTS

Setc:
        ORI #$0001, ESR
        RTS


ACTUALITZA_ZN_FLAGS:
        ANDI.W #$0001,ESR    ; Limpia registro de estado ESR menos c
        TST.W D2             ; Mira si D2 és zero flag Z
        BEQ Set_z
        BMI Set_n             ; Mira si D2 és negativo (flag N)
        RTS
Set_z:
        ORI #$0004, ESR
        RTS
Set_n:
        ORI #$0002, ESR
        RTS
        
CODIFICAR_A:
    MOVE.W EIR, D7           ; Carga instrucción en D7
    ANDI.W #$0038, D7        ; Extrae bits 3 a 5 (destino aaa)
    LSR #3, D7               ; Desplaza bits a la derecha para alinearlos
    CMP #0, D7
    BEQ CODIF_A_ET0
    CMP #1, D7
    BEQ CODIF_A_ET1
    CMP #2, D7
    BEQ CODIF_A_ER2
    CMP #3, D7
    BEQ CODIF_A_ER3
    CMP #4, D7
    BEQ CODIF_A_ER4
    CMP #5, D7
    BEQ CODIF_A_ER5
    RTS

CODIF_A_ET0: 
    LEA ET0, A0
    RTS
    
CODIF_A_ET1: 
    LEA ET1, A0
    RTS
    
CODIF_A_ER2: 
    LEA ER2, A0
    RTS
    
CODIF_A_ER3: 
    LEA ER3, A0
    RTS
    
CODIF_A_ER4: 
    LEA ER4, A0
    RTS
    
CODIF_A_ER5: 
    LEA ER5, A0
    RTS

CODIFICAR_B:
    MOVE.W EIR, D7           ; Carga instrucción en D7
    ANDI.W #$0007, D7        ; Extrae bits 0 a 2 (bbb)
    CMP #0, D7
    BEQ CODIF_B_ET0
    CMP #1, D7
    BEQ CODIF_B_ET1
    CMP #2, D7
    BEQ CODIF_B_ER2
    CMP #3, D7
    BEQ CODIF_B_ER3
    CMP #4, D7
    BEQ CODIF_B_ER4
    CMP #5, D7
    BEQ CODIF_B_ER5
    RTS

CODIF_B_ET0: 
    LEA ET0, A1
    RTS
    
CODIF_B_ET1: 
    LEA ET1, A1
    RTS
    
CODIF_B_ER2: 
    LEA ER2, A1
    RTS
    
CODIF_B_ER3: 
    LEA ER3, A1
    RTS
    
CODIF_B_ER4: 
    LEA ER4, A1
    RTS
    
CODIF_B_ER5: 
    LEA ER5, A1
    RTS

        
    ;--- FSUBR: FIN SUBRUTINAS
    
    

    ;--- IDECOD: INICIO DECOD
        ;*** Tras la etiqueta DECOD, debeis implementar la subrutina de 
        ;*** decodificacion, que debera ser de libreria, siguiendo la interfaz
        ;*** especificada en el enunciado
DECOD:
	        ; ESCRIBID VUESTRO CODIGO AQUI
    MOVE.L D0, -(A7) ; Guarda el contenido de D0 en la pila para 
                     ;no perder su valor
    MOVE.W 8(A7),D0 ; Carga la palabra (instrucción) desde la pila a D0 
                    ;(se accede a la instrucción desde el RTS)
  

    BTST #15,D0
    BNE NEXT_INC
    BTST #14,D0
    BNE NEXT_INC
    BTST #13,D0
    BNE NEXT_INC
    BTST #12,D0
    BNE NEXT_INC
    BTST #11,D0
    BNE NEXT_INC
    
DE_ID0:
    MOVE.W #0,D0
    BRA Final_Decod

NEXT_INC:
; --- INC: 00001 (ID = 1)
    BTST #15,D0
    BNE NEXT_ADD
    BTST #14,D0
    BNE NEXT_ADD
    BTST #13,D0
    BNE NEXT_ADD
    BTST #12,D0
    BNE NEXT_ADD
    BTST #11,D0
    BEQ NEXT_ADD
    
DE_ID1:
    MOVE.W #1,D0
    BRA Final_Decod

NEXT_ADD:
; --- ADD: 00010 (ID = 2)
    BTST #15,D0
    BNE NEXT_SUB
    BTST #14,D0
    BNE NEXT_SUB
    BTST #13,D0
    BNE NEXT_SUB
    BTST #12,D0
    BEQ NEXT_SUB
    BTST #11,D0
    BNE NEXT_SUB
    
DE_ID2:
    MOVE.W #2,D0
    BRA Final_Decod

NEXT_SUB:
; --- SUB: 00011 (ID = 3)
    BTST #15,D0
    BNE NEXT_CMP
    BTST #14,D0
    BNE NEXT_CMP
    BTST #13,D0
    BNE NEXT_CMP
    BTST #12,D0
    BEQ NEXT_CMP
    BTST #11,D0
    BEQ NEXT_CMP
    
DE_ID3:
    MOVE.W #3,D0
    BRA Final_Decod

NEXT_CMP:
; --- CMP: 00100 (ID = 4)
    BTST #15,D0
    BNE NEXT_AND
    BTST #14,D0
    BNE NEXT_AND
    BTST #13,D0
    BEQ NEXT_AND
    BTST #12,D0
    BNE NEXT_AND
    BTST #11,D0
    BNE NEXT_AND
    
DE_ID4:
    MOVE.W #4,D0
    BRA Final_Decod

NEXT_AND:
; --- AND: 00101 (ID = 5)
    BTST #15,D0
    BNE NEXT_OR
    BTST #14,D0
    BNE NEXT_OR
    BTST #13,D0
    BEQ NEXT_OR
    BTST #12,D0
    BNE NEXT_OR
    BTST #11,D0
    BEQ NEXT_OR
    
DE_ID5:
    MOVE.W #5,D0
    BRA Final_Decod

NEXT_OR:
; --- OR: 00110 (ID = 6)
    BTST #15,D0
    BNE NEXT_NOT
    BTST #14,D0
    BNE NEXT_NOT
    BTST #13,D0
    BEQ NEXT_NOT
    BTST #12,D0
    BEQ NEXT_NOT
    BTST #11,D0
    BNE NEXT_NOT
    
DE_ID6:
    MOVE.W #6,D0
    BRA Final_Decod

NEXT_NOT:
; --- NOT: 00111 (ID = 7)
    BTST #15,D0
    BNE NEXT_TRA
    BTST #14,D0
    BNE NEXT_TRA
    BTST #13,D0
    BEQ NEXT_TRA
    BTST #12,D0
    BEQ NEXT_TRA
    BTST #11,D0
    BEQ NEXT_TRA
    
DE_ID7:
    MOVE.W #7,D0
    BRA Final_Decod

NEXT_TRA:
; --- TRA: 01000 (ID = 8)
    BTST #15,D0
    BNE NEXT_LEA
    BTST #14,D0
    BEQ NEXT_LEA
    BTST #13,D0
    BNE NEXT_LEA
    BTST #12,D0
    BNE NEXT_LEA
    BTST #11,D0
    BNE NEXT_LEA
    
DE_ID8:
    MOVE.W #8,D0
    BRA Final_Decod

NEXT_LEA:
; --- LEA: 01001 (ID = 9)
    BTST #15,D0
    BNE NEXT_STI
    BTST #14,D0
    BEQ NEXT_STI
    BTST #13,D0
    BNE NEXT_STI
    BTST #12,D0
    BNE NEXT_STI
    BTST #11,D0
    BEQ NEXT_STI
    
DE_ID9:
    MOVE.W #9,D0
    BRA Final_Decod

NEXT_STI:
; --- STI: 01010 (ID = 10)
    BTST #15,D0
    BNE NEXT_LDI
    BTST #14,D0
    BEQ NEXT_LDI
    BTST #13,D0
    BNE NEXT_LDI
    BTST #12,D0
    BEQ NEXT_LDI
    BTST #11,D0
    BNE NEXT_LDI
    
DE_ID10:
    MOVE.W #10,D0
    BRA Final_Decod

NEXT_LDI:
; --- LDI: 01011 (ID = 11)
    BTST #15,D0
    BNE NEXT_STO
    BTST #14,D0
    BEQ NEXT_STO
    BTST #13,D0
    BNE NEXT_STO
    BTST #12,D0
    BEQ NEXT_STO
    BTST #11,D0
    BEQ NEXT_STO
    
DE_ID11:
    MOVE.W #11,D0
    BRA Final_Decod

NEXT_STO:
; --- STO: 01100 (ID = 12)
    BTST #15,D0
    BNE NEXT_LOA
    BTST #14,D0
    BEQ NEXT_LOA
    BTST #13,D0
    BEQ NEXT_LOA
    BTST #12,D0
    BNE NEXT_LOA
    BTST #11,D0
    BTST #11, D0
    BNE NEXT_LOA
    
DE_ID12:
    MOVE.W #12,D0
    BRA Final_Decod

NEXT_LOA:
; --- LOA: 01101 (ID = 13)
    BTST #15, D0     
    BNE NEXT_JMN
    BTST #14, D0     
    BEQ NEXT_JMN
    BTST #13, D0     
    BEQ NEXT_JMN
    BTST #12, D0
    BNE NEXT_JMN
    BTST #11, D0
    BEQ NEXT_JMN

DE_ID13:
    MOVE.W #13, D0
    BRA Final_Decod

NEXT_JMN:
; --- JMN: 1000 (ID = 14)
    NEXT_JMN:
    BTST #15, D0  
    BEQ NEXT_JMZ
    BTST #14, D0
    BNE NEXT_JMZ
    BTST #13, D0 
    BNE NEXT_JMZ
    BTST #12, D0 
    BNE NEXT_JMZ

DE_ID14:
    MOVE.W #14, D0
    BRA Final_Decod

NEXT_JMZ:
; --- JMZ: 1001 (ID = 15)
    NEXT_JMZ:
    BTST #15, D0    
    BEQ NEXT_JMI
    BTST #14, D0      
    BNE NEXT_JMI
    BTST #13, D0     
    BNE NEXT_JMI
    BTST #12, D0     
    BEQ NEXT_JMI

DE_ID15:
    MOVE.W #15, D0
    BRA Final_Decod

NEXT_JMI:
    BTST #15, D0     
    BEQ NEXT_HLT
    BTST #14, D0     
    BNE NEXT_HLT
    BTST #13, D0  
    BEQ NEXT_HLT
    BTST #12, D0   
    BNE NEXT_HLT

DE_ID16:
    MOVE.W #16, D0
    BRA Final_Decod
    
NEXT_HLT:
; --- HLT: 11xxxx (ID = 17)
    BTST #15,D0
    BEQ Final_Decod
    BTST #14,D0
    BEQ Final_Decod
DE_ID17:
    MOVE.W #17,D0

Final_Decod:

    MOVE.W D0, 10(A7)   ; Guarda el ID decodificado en la pila 
    MOVE.L (A7)+, D0 ; Restaura el valor original de D0
    RTS ;Retorna de la subrutina


    ;--- FDECOD: FIN DECOD
Fin_Programa:
    SIMHALT              ; Instrucción de parada (simulación)
    END    START




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
