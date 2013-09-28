/******************************************************************************
*	main.s
*	 for ZergOS by Jeppe Terndrup
*
*	main.s contains the main operating system, and IVT code.
******************************************************************************/
.section .init
.globl _start
_start:

/*
* Branch to the actual main code.
*/
b main

.section .text

/*
* main operating system function which returns nothing and takes no parameters, ikke sandt?
* Signature: void main(void)
*/
main:

/*
* Set the stack point to 0x8000.
*/
	mov sp,#0x8000

/* 
* Setup the screen.
*/
	mov r0,#1024
	mov r1,#768
	mov r2,#16
	bl InitialiseFrameBuffer

/* 
* Check for a failed frame buffer.
*/
	teq r0,#0
	bne noError$
		
	mov r0,#16
	mov r1,#1
	bl SetGpioFunction

	mov r0,#16
	mov r1,#0
	bl SetGpio

	error$:
		b error$

	noError$:

	fbInfoAddr .req r4
	mov fbInfoAddr,r0

/*
* Init Drawing and welcome messages
*/
	bl SetGraphicsAddress

	bl UsbInitialise
	
reset$:
	mov sp,#0x8000
	bl TerminalClear

	ldr r0,=welcome
	mov r1,#welcomeEnd-welcome
	bl Print

loop$:		
	ldr r0,=prompt
	mov r1,#promptEnd-prompt
	bl Print

	ldr r0,=command
	mov r1,#commandEnd-command
	bl ReadLine

	teq r0,#0
	beq loopContinue$

	mov r4,r0
	
	ldr r5,=command
	ldr r6,=commandTable
	
	ldr r7,[r6,#0]
	ldr r9,[r6,#4]
	commandLoop$:
		ldr r8,[r6,#8]
		sub r1,r8,r7

		cmp r1,r4
		bgt commandLoopContinue$

		mov r0,#0	
		commandName$:
			ldrb r2,[r5,r0]
			ldrb r3,[r7,r0]
			teq r2,r3			
			bne commandLoopContinue$
			add r0,#1
			teq r0,r1
			bne commandName$

		ldrb r2,[r5,r0]
		teq r2,#0
		teqne r2,#' '
		bne commandLoopContinue$

		mov r0,r5
		mov r1,r4
		mov lr,pc
		mov pc,r9
		b loopContinue$

	commandLoopContinue$:
		add r6,#8
		mov r7,r8
		ldr r9,[r6,#4]
		teq r9,#0
		bne commandLoop$	

	ldr r0,=commandUnknown
	mov r1,#commandUnknownEnd-commandUnknown
	ldr r2,=formatBuffer
	ldr r3,=command
	bl FormatString

	mov r1,r0
	ldr r0,=formatBuffer
	bl Print

loopContinue$:
	bl TerminalDisplay
	b loop$

echo:
	cmp r1,#5
	movle pc,lr

	add r0,#5
	sub r1,#5 
	b Print
 
ok:
	teq r1,#5
	beq okOn$
	teq r1,#6
	beq okOff$
	mov pc,lr

	okOn$:
		ldrb r2,[r0,#3]
		teq r2,#'o'
		ldreqb r2,[r0,#4]
		teqeq r2,#'n'
		movne pc,lr
		mov r1,#0
		b okAct$

	okOff$:
		ldrb r2,[r0,#3]
		teq r2,#'o'
		ldreqb r2,[r0,#4]
		teqeq r2,#'f'
		ldreqb r2,[r0,#5]
		teqeq r2,#'f'
		movne pc,lr
		mov r1,#1

	okAct$:
		mov r0,#16
		b SetGpio
	
.section .data
.align 2
welcome:
	.ascii "$$$$$$$$\                               $$$$$$\   $$$$$$\  \n"  
	.ascii "\____$$  |                             $$  __$$\ $$  __$$\ \n"
	.ascii "    $$  / $$$$$$\   $$$$$$\   $$$$$$\  $$ /  $$ |$$ /  \__| \n"
	.ascii "   $$  / $$  __$$\ $$  __$$\ $$  __$$\ $$ |  $$ |\$$$$$$\  \n"
	.ascii "  $$  /  $$$$$$$$ |$$ |  \__|$$ /  $$ |$$ |  $$ | \____$$\  \n"
	.ascii " $$  /   $$   ____|$$ |      $$ |  $$ |$$ |  $$ |$$\   $$ | \n"
	.ascii "$$$$$$$$\\$$$$$$$\ $$ |      \$$$$$$$ | $$$$$$  |\$$$$$$  | \n"
	.ascii "\________|\_______|\__|       \____$$ | \______/  \______/  \n"
	.ascii "                             $$\   $$ |  \n"                   
	.ascii "                             \$$$$$$  | \n"                    
	.ascii "                              \______/   \n"
	.ascii "ZergOS v1.0 Alpha by Jeppe G. Terndrup - Copyright 2013 \n"
	.ascii "Reach the author at jeppe.terndrup@gmail.com. \n"
	.ascii "It is slimey and chaotic, just like the Zerg. But it's nice ASCII art, ikke sandt?? \n"
welcomeEnd:
.align 2
prompt:
	.ascii "\n> "
promptEnd:
.align 2
command:
	.rept 128
		.byte 0
	.endr
commandEnd:
.byte 0
.align 2
commandUnknown:
	.ascii "Unknown command: `%s'. It is wrong, ikke sandt? \n"
commandUnknownEnd:
.align 2
formatBuffer:
	.rept 256
	.byte 0
	.endr
formatEnd:

.align 2
commandStringEcho: .ascii "echo"
commandStringReset: .ascii "reset"
commandStringOk: .ascii "ok"
commandStringCls: .ascii "clear"
commandStringEnd:

.align 2
commandTable:
.int commandStringEcho, echo
.int commandStringReset, reset$
.int commandStringOk, ok
.int commandStringCls, TerminalClear
.int commandStringEnd, 0

