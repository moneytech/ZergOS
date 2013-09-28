/******************************************************************************
*	random.s
*	 for ZergOS by Jeppe Terndrup
*
*	 contains code to do with generating pseudo random numbers.
******************************************************************************/

/*
* Function with an input of the last number it generated, and an 
* output of the next number in a pseduo random number sequence.
* Signature: u32 Random(u32 lastValue);
*/
.globl Random
Random:
	xnm .req r0
	a .req r1
	
	mov a,#0xef00
	mul a,xnm
	mul a,xnm
	add a,xnm
	.unreq xnm
	add r0,a,#73
	
	.unreq a
	mov pc,lr
