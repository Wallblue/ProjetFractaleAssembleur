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
%define CONFIGURE_NOTIFY 16
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
x1:		dq -2.1
x2:		dq 0.6
y1:		dq -1.2
y2:		dq 1.2
zoomCoeff:	dq 100.0
askZoom:	db "Quel zoom voulez-vous ? (1/100)", 10, 0
dimensions:	db "Largeur : %d | Hauteur : %d", 10, 0
askValidation:	db "Ces dimensions vous vont-elles ? (y/n)", 10, 0
askChar:	db " %c", 0
askDouble:	db "%lf", 0
event: times 24 dq 0

section .bss
win_x:		resd 1
win_y:		resd 1
choice:		resb 1
zoom:		resq 1
display_name:	resq 1
screen:		resd 1
depth:		resd 1
connection:	resd 1
width:		resd 1
height:		resd 1
window:		resq 1
gc:		resq 1

section .text
main:
	push rbp
start:
	;Saisie du Zoom
	mov rax, 1
	mov rdi, STDOUT
	mov rsi, askZoom
	mov rdx, 32
	syscall

	mov rdi, askDouble
	mov rsi, zoom
	mov rax, 0
	call scanf

	movsd xmm0, [zoomCoeff]
	mulsd xmm0, [zoom]
	movsd [zoom], xmm0

	;Calcul de la taille de la fenetre
	movsd xmm0, qword[x2]
	subsd xmm0, [x1]
	mulsd xmm0, [zoom]
	cvtsd2si eax, xmm0
	mov [win_x], eax

	movsd xmm0, qword[y2]
	subsd xmm0, [y1]
	mulsd xmm0, [zoom]
	cvtsd2si eax, xmm0
	mov [win_y], eax

	;Affichage des dimensions
	mov rdi, dimensions 
	mov rsi, [win_x]
	mov rdx, [win_y]
	mov rax, 0
	call printf

	;On demande si les dimensions vont à l'utilisateur
	mov rax, 1
	mov rdi, STDOUT
	mov rsi, askValidation
	mov rdx, 39
	syscall

	mov rdi, askChar
	mov rsi, choice
	mov rax, 0
	call scanf

	cmp byte[choice], 121
	je windowCreation
	cmp byte[choice], 89
	je windowCreation

	jmp start

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
	jmp flush

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
