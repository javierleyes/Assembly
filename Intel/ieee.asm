segment pila stack
	resb 1024
	
segment datos data
	;path al archivo 
	fileName db "numeros.dat",0
	
	;handles del archivo
	fHandle	 resw 1
	
	;registro leido
	registro resb 4
	
	msgBienvenida db 10,13,"Se leera el archivo y se mostraran por pantalla los IEEE 754 en base 2: $"
	msgFin        db 10,13,"Fin del archivo $"
	msgErrOpen	  db 10,13,"Error en apertura $"
	msgErrRead	  db 10,13,"Error en lectura $"
	msgErrClose	  db 10,13,"Error en cierre $"
	
	msgBlanco     db 10,13,"$"

	signo         db "+$"
	presicion     db "1,$"
	mantisa       db "                       $"
	base          db " x 10 ^ $"
	exponente     db "        $"
	
segment codigo code
..start:

	mov	ax,datos		
	mov	ds,ax			;ds <-- dir del segmento de datos
	mov	es,ax			;es <-- dir del segmento de datos 
	mov	ax,pila			
	mov	ss,ax			;ss <-- dir del segmento de pila

	mov dx,msgBienvenida
	call printMsg
	
	;abre el archivo para la lectura
	call fOpen
	
;mientras que haya registros	
ciclo:
	call fRead
	
	mov dx,msgBlanco
	call printMsg
	
	;pongo el signo +
	mov si,0
	mov dl,43 ;caracter "+"
	mov [signo+si],dl

	;proceso el numero, copio 8 bits al registro 
	mov al,byte[registro]
	
	;desplazo 7 bits a derecha (0000 0001), analizo bits de signo.
	mov cl,7
	shr al,cl ;al = 0000 000(1/0) (signo)
	cmp al,0000
	;si es igual --> exponente
	je  expo
	
;si es distinto --> cambio el signo a menos (-)
cambiarSigno:
	mov si,0
	mov dl,45 ;caracter "-"
	mov [signo+si],dl
	
expo:
	;copio 16 bits al registro 
	mov ax,word[registro]
	;desplazo 7 bits a la derecha
	mov cl,7
	shr ax,cl ;al = exponente en exceso
	mov ah,0
	;resto 127
	sub al,127 ;al = exponente en BPF c/s
	
	mov si,0
	mov cx,8
copiarExp:	
	mov ah,0
	shl ax,1
	add ah,48
	mov byte[exponente+si],ah
	add si,1
	loop copiarExp
	
mant:	
	;desplazar 23 bits restantes
	;copio 7 bits
	mov ax,word[registro]
	mov cl,9
	shl ax,cl 
	
	;copiar ah a la variable "mantisa"
	mov si,0
	mov cx,7
	
	mov cl,8
	shr ax,cl
copiarMant1:
	mov ah,0
	shl ax,1
	add ah,48
	mov [mantisa+si],ah
	add si,1
	loop copiarMant1

	;copio 16 bits
	mov ax,word[registro+2]
	;copiar ax a la variable "mantisa"
	mov si,7
	mov cx,8
	
	mov cl,8
	shr ax,cl
copiarMant2:	
	mov ah,0
	shl ax,1
	add ah,48
	mov [mantisa+si],ah
	add si,1
	loop copiarMant2
	
	;copio 8 bits
	mov al,byte[registro+3]
	mov si,15
	mov cx,8
copiarMant3:
	mov ah,0
	shl ax,1
	add ah,48
	mov [mantisa+si],ah
	add si,1
	loop copiarMant3
	
	;muestro el numero	
	mov dx,signo
	call printMsg
	mov dx,presicion
	call printMsg
	mov dx,mantisa
	call printMsg
	mov dx,base
	call printMsg	
	mov dx,exponente
	call printMsg

	;fin del ciclo
	jmp ciclo
	
fOpen:
	mov	al,0		    ;al = tipo de acceso (0=lectura; 1=escritura; 2=lectura y escritura)
	mov	dx,fileName	    ;dx = dir del nombre del archivo
	mov	ah,3dh		    ;ah = servicio para abrir archivo 3dh
	int	21h
	jc	errOpen
	mov	[fHandle],ax	; en ax queda el handle del archivo
	ret
fRead:	
	mov	bx,[fHandle]	;bx = handle del archivo
	mov	cx,4			;cx = cantidad de bytes a leer
	mov	dx,registro		;dx = dir del area de memoria q contiene los bytes leidos del archivo
	mov	ah,3fh			;ah = servicio para leer un archivo: 3fh
	int	21h
	jc  errRead
    cmp ax,4
    jne finArch
	ret
finArch:
	mov	dx,msgFin
	call printMsg
	mov	bx,[fHandle]	;bx = handle del archivo
	mov	ah,3eh		;ah = servicio para cerrar archivo: 3eh
	int	21h
	jc	errClose
fin:
	mov  ax,4c00h  ;retornar al DOS
	int  21h	
errOpen:
	mov	dx,msgErrOpen
	call printMsg
	jmp	fin
errRead:
	mov	dx,msgErrRead
	call printMsg
	jmp fin
errClose:
	mov	dx,msgErrClose
	call printMsg
	ret
printMsg:
	mov	ah,9  ; servicio 9 para int 21 -- Impmrimir cadena en pantalla
	int	21h
	ret