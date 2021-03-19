<h1 align="center"> Bootloader of the main program. Exception handling. Output data to the debug port or console</h1>

Learn how to work with RAM, use special instructions, use Cortex-M4 processor shutdowns. Creating a minimum system bootloader. Learn how to use data output through a debug port (or console).


<h2 align="center">📝 Task</h2>

1. Understand how bootloader, exception handling, and semihosting should work.
2. Modify the expression calculation file from the Lab Work 2 (insert a vector table into it), and modify `Makefile` so that `<your_file_name>.bin` file is created automatically.
3. Create a `bootloader` that will run the program (for example, kernel.bin).
4. Run the program in gdb, demonstrate the launch of the loaded program and output the result to the console.

| Commands for working with memory | Increment/Decrement of the address register | Type of shift | Number of bytes to shift |
|:--------------------------------:|:-------------------------------------------:|:-------------:|:------------------------:|
|             LDR, STR             |                  decrement                  |    register   |             4            |


<h2 align="center">📙 Description</h2>

The purpose of this laboratory work is to develop a primitive program loader, ie to build a program that can byte-by-byte another program into RAM and run it from there.Consider this program in more detail on the example:

<details>
<summary>Content of <cite>kernel.S</cite> (with comments)</summary><p align="left">

```assembly
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
    
// ((a & b) >> 1) + c!
	mov r0, A
	and r0, B        // A & B
	lsr r1, r0, #1   // (A & B) >> 1
	mov r0, #1
	mov r2, C
	bl factorial
	add r3, r0, r1   // ((A & B) >> 1) + C!
        
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
```
</details>

Using the `.section` `.interrupt_vector` directives, we specify a vector interrupt table. The first row of the table defines the initial state of the `Stack Pointer`, ie the address from which the stack begins. Next, we specify the `__kernel_reset__` program address to handle the `RESET` exception, indicating the use of `thumb` instructions.

This program outputs the data string to the debug console, then executes an expression from the previous lab, outputs the contents of `r3` to the debug console and is in an infinite loop. To display the result of the program, the procedure `dbgput_num` is used, the principle of operation can be found in `print.s`. To output the contents of a certain register, you need to copy its value to `r0` and only then call the procedure.

Now consider an example of the bootloader:

<details>
  <summary>Content of <cite>bootloader.S</cite></summary><p align="left">
  
```assembly
.syntax unified
.cpu cortex-m4
//.fpu softvfp
.thumb

.global bootload

.section .rodata
	image: .incbin "kernel.bin"
	end_of_image:
	str_boot_start: .asciz "bootloader started"
	str_boot_end: .asciz "bootloader end"
	str_boot_indicate: .asciz "#"


.section .text

bootload:
	ldr r0, =str_boot_start
	bl dbgput_line
	ldr r0, =end_of_image
	ldr r1, =image
	ldr r2, =_ram_start

	sub r6, r0, r1
	add r4, r6, r2

loop:
        ldr r3, [r0], #-4
        str r3, [r4], #-4
        cmp r0, r1
        bhi loop

bl newline
ldr r0, =str_boot_end
bl dbgput_line

ldr lr, =bootload_end
add lr, #1
ldr r2, =_ram_start

add r2, #4 // go to __reset_kernel__
ldr r0, [r2]
bx r0


bootload_end:
	b bootload_end
```
</details>

The beginning of the file is the same as in `kernel.S`. Next, we specify the label that will be responsible for loading the `bootload.S` into RAM as global, so that this label is visible from `start.S`. Next, in the `.rodata` section, we create strings of ASCII characters to verify that the program is working properly, and `image`, `end_of_image` labels that contain the memory address where the program begins and ends (`end_of_image` points to the next word after the last word of the program).

For example, we will load the program sequentially, using the instructions `ldr` and `str`:

```assembly
ldr r0, =str_boot_start
	bl dbgput_line
	ldr r0, =end_of_image
	ldr r1, =image
	ldr r2, =_ram_start
```

You must first load the start and end addresses of the program and the start address of the RAM into the registers. Also using the `dbgput_line` procedure, the string `str_boot_start` is displayed in the debug console. You can get acquainted with the principle of operation of procedures in the file `print.S`.

After loading the start and end addresses of the program into the appropriate registers, we will load it sequentially into the RAM:

```assembly
sub r6, r0, r1
add r4, r6, r2

loop:
        ldr r3, [r0], #-4
        str r3, [r4], #-4
        cmp r0, r1
        bhi loop
```

First, using the `ldr` statement, we load the word of the program located at the address in `r0`, then unload it into RAM at the address in `r4`, and move on to the next word. The cycle ends as soon as the last word of the program is loaded.


Once the load is complete, all you have to do is go to the beginning of RAM to start running the loaded program:

```assembly
bl newline
ldr r0, =str_boot_end
bl dbgput_line
```

Using the `newline` and `dbgput_line` procedures, the text is output to the debug console, after which we load the start address of the RAM with the `ldr` command:

```assembly
ldr lr, =bootload_end
add lr, #1
ldr r2, =_ram_start
```

Since there is a vector table at the beginning of the program, we need to go to the next word that contains the address of the subroutine that is responsible for handling the `RESET` exception. In this case, this is the address of the `__reset_lernel__` subroutine:

```assembly
add r2, #4 // go to __reset_kernel__
ldr r0, [r2]
bx r0

bootload_end:
	b bootload_end
```


<h2 align="center">🚀 How To Run</h2>

Build the project with make:

```sh
>>> make
```

Start the qemu emulator with make qemu:

```sh
>>> make qemu
```

In another terminal, start the gdb debugger with the command `gdb-multiarch firmware.elf`. And run the program step by step. Demonstrate the value of the registers.

```sh
(gdb) target extended-remote:1234
(gdb) layout regs
(gdb) step
```

Alternatively, once you’ve connected to the chip, you type `continue`, wait a few seconds, and then hit Ctrl+C. If it asks, ‘Give up waiting?’, enter y for ‘yes’. After the program has run for a bit and then stopped, you can enter the `info registers` or `layout regs` command

```sh
(gdb) target extended-remote:1234
(gdb) continue
(gdb) layout regs
```
