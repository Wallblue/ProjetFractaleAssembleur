extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XNextEvent
extern XDrawPoint
extern XDrawLine

extern printf
extern scanf

;Event masks
%define EVENT_MASK 131077
%define StructureNotifyMask 131072
%define KEY_PRESS_MASK 1
%define BUTTON_PRESS_MASK 4
%define MAP_NOTIFY 19

;Events to listen
%define KEY_PRESS 2
%define BUTTON_PRESS 4
%define EXPOSE 12
%define CONFIGURE_NOTIFY 22
%define CREATE_NOTIFY 16

;Sizes
%define BYTE 1
%define WORD 2
%define DWORD 4
%define QWORD 8

;Std
%define STDIN 0
%define STDOUT 1
%define STDERR 2

global main

section .data

a: dq -0.75
b: dq 0.0
taille: dq 400
xmin: dq -1.25
xmax: dq 1.25
ymin: dq -1.25
ymax: dq 1.25
iterationmax: dw 200
event: times 24 dq 0
floatZero:		dq 0.0
floatTwo:		dq 2.0
floatFour:		dq 4.0
win_x:			dd 400
win_y:			dd 400

section .bss
choice:			resb 1
zoom:			resq 1
display_name:	resq 1
screen:			resd 1
depth:			resd 1
connection:		resd 1
width:			resd 1
height:			resd 1
window:			resq 1
gc:				resq 1
i:              resw 1
x:              resq 1
y:              resq 1
stock:          resq 1
colour:			resq 1

section .text
main:
	push rbp

windowCreation:
	;Recuperation du display et du screen
	xor rdi, rdi
	call XOpenDisplay
	mov qword[display_name], rax

	mov rax, qword[display_name]
	mov eax, dword[rax + 0xe0]
	mov dword[screen], eax

	;On recupere la fenetre racine
	mov rdi, qword[display_name]
	mov esi, dword[screen]
	call XRootWindow
	mov rbx, rax

	;Creation de la fenetre
	mov rdi, qword[display_name]
	mov rsi, rbx
	mov rdx, 10
	mov rcx, 10
	mov r8, [win_x] ;largeur
	mov r9, [win_y] ;hauteur
	push 0xFFFFFF	;fond
	push 0x00FF00
	push 1
	call XCreateSimpleWindow
	mov qword[window], rax

	;Definition du eventMask
	mov rdi, qword[display_name]
	mov rsi, qword[window]
	mov rdx, EVENT_MASK
	call XSelectInput

	;On "construit" la fenetre
	mov rdi, qword[display_name]
	mov rsi, qword[window]
	call XMapWindow

	;On cree le graphics context
	mov rsi, qword[window]
	mov rdx, 0
	mov rcx, 0
	call XCreateGC
	mov qword[gc], rax

	;On definit la couleur par defaut en noir
	mov rdi, qword[display_name]
	mov rsi, qword[gc]
	mov rdx, 0x000000
	call XSetForeground

eventLoop:
	mov rdi, qword[display_name]
	mov rsi, event
	call XNextEvent

	cmp dword[event], CONFIGURE_NOTIFY
	je dessin

	cmp dword[event], KEY_PRESS
	je closeDisplay

	jmp eventLoop
    
    
dessin:

    mov eax, 0
    mov ebx, 0
    
    boucle_ligne:
    
    cmp ax, word[taille]
    ja flush
    
        boucle_colonne:
        
        cmp bx, word[taille]
        ja inc_line
        
        mov word[i], 1
        
        ;calcul x
        movsd xmm0, qword[xmax]
        subsd xmm0, [xmin]
        
        cvtsi2sd xmm1, ebx
        mulsd xmm0, xmm1
        
        cvtsi2sd xmm2, [taille]
        divsd xmm0, xmm2
        
        addsd xmm0, [xmin]
        movsd qword[x], xmm0
        
        ;calcul y 
        movsd xmm0, qword[ymax]
        subsd xmm0, [ymin]
        
        cvtsi2sd xmm1, eax
        mulsd xmm0, xmm1
        
        cvtsi2sd xmm2, qword[taille]
        divsd xmm0, xmm2
        
        movsd xmm3, qword[ymax]
        subsd xmm3, xmm0
        movsd qword[y], xmm3
        
            test_point:
            mov dx, word[i]
            cmp dx, word[iterationmax]
            ja sie
            
            movsd xmm0, qword[x]
            mulsd xmm0, [x]
            
            movsd xmm1, qword[y]
            mulsd xmm1, [y]
            
            addsd xmm0, xmm1
            ucomisd xmm0, qword[floatFour]
            ja sie
            
            movsd xmm0, qword[x]
            movsd qword[stock], xmm0
            
            mulsd xmm0, qword[x]
            
            movsd xmm1, qword[y]
            mulsd xmm1, [y]
            
            subsd xmm0, xmm1
            addsd xmm0, [a]
            movsd qword[x], xmm0
            
            movsd xmm3, qword[floatTwo]
            mulsd xmm3, [stock]
            movsd xmm1, qword[y]
            mulsd xmm1, xmm3
            addsd xmm1, [b]
            movsd qword[y], xmm1

            inc word[i]
            jmp test_point
            
        sie:
        mov dx, word[i]
        cmp dx, word[iterationmax]
        jbe sinon
        
        movsd xmm0, qword[x]
        mulsd xmm0, qword[x]
        movsd xmm1, qword[y]
        mulsd xmm1, qword[y]

        addsd xmm0, xmm1
        ucomisd xmm0, qword[floatFour]
        ja sinon
        
            push rax
            push rbx
            xor rdx, rdx
            xor rax, rax
            xor rbx, rbx
            mov ax, cx
            mov edx, 0
            mul edx
            xor rdx, rdx
            div word[i]
            mov bl, al
            shl rbx, 8
            mov bl, al
            shl rbx, 8
            mov bl, 0
            mov rdx, rbx
            
            mov rdi, qword[display_name]
            mov rsi, qword[gc]
            call XSetForeground

            mov rdi, qword[display_name]
            mov rsi, qword[window]
            mov rdx, qword[gc]
                      
            pop rbx
            pop rax
            
            mov ecx, ebx	; coordonnée en x
            mov r8d, eax	; coordonnée en y
            push rax ; pour garder la valeur de rax
            push rbx
            
            call XDrawPoint
            
            pop rbx
            pop rax
        jmp incrementation
    
        sinon:
            
            push rax
            push rbx
            
            mov ax, cx
            mov edx, 200
            mul edx
            xor rdx, rdx
            div word[i]
            mov bl, al
            shl rbx, 8
            mov bl, al
            shl rbx, 8
            mov bl, 143
            mov rdx, rbx
            
            
            mov rdi, qword[display_name]
            mov rsi, qword[gc]
            call XSetForeground

            mov rdi, qword[display_name]
            mov rsi, qword[window]
            mov rdx, qword[gc]
                      
            pop rbx
            pop rax
            
            mov ecx, ebx	; coordonnée en x
            mov r8d, eax	; coordonnée en y
            push rax ; pour garder la valeur de rax
            push rbx
            
            call XDrawPoint
            
            pop rbx
            pop rax
        
        incrementation:
        inc bx        
        jmp boucle_colonne
        
    inc_line:
        inc ax
        mov bx, 0
        jmp boucle_ligne
    
flush:
    mov rdi, qword[display_name]
    call XFlush
    jmp eventLoop

closeDisplay:
	mov rax, qword[display_name]
	mov rdi, rax
	call XCloseDisplay

end:
	pop rbp
	mov rax, 60
	mov rdi, 0
	syscall
	ret
