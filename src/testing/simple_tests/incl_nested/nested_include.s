	.text
	.file	"edsger-program"
	.globl	g_i_0                   # -- Begin function g_i_0
	.p2align	4, 0x90
	.type	g_i_0,@function
g_i_0:                                  # @g_i_0
	.cfi_startproc
# %bb.0:                                # %entry
                                        # kill: def $edi killed $edi def $rdi
	movw	%di, -2(%rsp)
	leal	(%rdi,%rdi,2), %eax
                                        # kill: def $ax killed $ax killed $eax
	retq
.Lfunc_end0:
	.size	g_i_0, .Lfunc_end0-g_i_0
	.cfi_endproc
                                        # -- End function
	.globl	f_ii_0                  # -- Begin function f_ii_0
	.p2align	4, 0x90
	.type	f_ii_0,@function
f_ii_0:                                 # @f_ii_0
	.cfi_startproc
# %bb.0:                                # %entry
	pushq	%rbx
	.cfi_def_cfa_offset 16
	subq	$16, %rsp
	.cfi_def_cfa_offset 32
	.cfi_offset %rbx, -16
	movw	%di, 14(%rsp)
	movw	%si, 12(%rsp)
	callq	g_i_0@PLT
	movl	%eax, %ebx
	movzwl	12(%rsp), %edi
	callq	g_i_0@PLT
                                        # kill: def $ax killed $ax def $eax
	addl	%ebx, %eax
                                        # kill: def $ax killed $ax killed $eax
	addq	$16, %rsp
	.cfi_def_cfa_offset 16
	popq	%rbx
	.cfi_def_cfa_offset 8
	retq
.Lfunc_end1:
	.size	f_ii_0, .Lfunc_end1-f_ii_0
	.cfi_endproc
                                        # -- End function
	.globl	h_i_0                   # -- Begin function h_i_0
	.p2align	4, 0x90
	.type	h_i_0,@function
h_i_0:                                  # @h_i_0
	.cfi_startproc
# %bb.0:                                # %entry
                                        # kill: def $edi killed $edi def $rdi
	movw	%di, -2(%rsp)
	leal	23(%rdi), %eax
                                        # kill: def $ax killed $ax killed $eax
	retq
.Lfunc_end2:
	.size	h_i_0, .Lfunc_end2-h_i_0
	.cfi_endproc
                                        # -- End function
	.globl	main                    # -- Begin function main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %entry
	pushq	%rax
	.cfi_def_cfa_offset 16
	movl	$2, %edi
	movl	$3, %esi
	callq	f_ii_0@PLT
                                        # kill: def $ax killed $ax def $eax
	movl	%eax, %edi
	callq	h_i_0@PLT
                                        # kill: def $ax killed $ax def $eax
	movl	%eax, %edi
	callq	writeInteger_i_0@PLT
	movl	$10, %edi
	callq	writeChar_c_0@PLT
	popq	%rax
	.cfi_def_cfa_offset 8
	retq
.Lfunc_end3:
	.size	main, .Lfunc_end3-main
	.cfi_endproc
                                        # -- End function
	.section	".note.GNU-stack","",@progbits
