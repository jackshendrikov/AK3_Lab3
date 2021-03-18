.syntax unified
.cpu cortex-m4
.thumb

#define A #5
#define B #7
#define C #3

// Global memory locations.
.global vtable_kernel
.global __kernel_reset__

.type vtable_kernel, %object
.type __kernel_reset__, %function

.section .interrupt_vector

vtable_kernel:
	.word __stack_start 
	.word __kernel_reset__+1
	.size vtable_kernel, .-vtable_kernel

.section .rodata
	data: .asciz "kernel started!\n"
	final: .asciz "Value in register #3: "

.section .text
__kernel_reset__:
	ldr r0, =data
	bl dbgput_line
    
// calculate 
	mov r0, A
	and r0, B
	lsr r1, r0, #1
	mov r0, #1
	mov r2, C
	bl factorial
	add r3, r0, r1 
        
	ldr r0, =final
	bl dbgput
	mov r0, r3
	bl dbgput_num
    
end:
	b end

factorial:
	push { lr }
	.fact_calc:
		mul r0, r2
		subs r2, #1
		bne .fact_calc
	pop { pc }
