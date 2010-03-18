	.text
.globl _objc_msgSend
_objc_msgSend:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$16, %esp
	pushl	12(%ebp)
	pushl	8(%ebp)
	call	L_objc_msg_lookup$stub
	mov  %ebp, %esp

	pop  %ebp
	jmp	*%eax
.globl _objc_msgSendSuper
_objc_msgSendSuper:
	pushl	%ebp
	movl	%esp, %ebp

   pushl	%edi
   pushl %esi
	subl	$16, %esp
	movl	8(%ebp), %edi
	movl	12(%ebp), %esi
   movl	%esi, 4(%esp)
	movl	%edi, (%esp)
	call	L_objc_msg_lookup_super$stub
   // TODO: incomprehensible. rewrite using %eax for temp value
   movl  (%edi), %esi
	movl	%esi, 8(%ebp)
   
   addl  $16, %esp
   popl %esi
   popl %edi
   mov  %ebp, %esp
	pop  %ebp
	jmp	*%eax
.globl _objc_msgSend_fpret
_objc_msgSend_fpret:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$16, %esp
	pushl	12(%ebp)
	pushl	8(%ebp)
   
	call	L_objc_msg_lookup$stub
	mov  %ebp, %esp
	pop  %ebp

	jmp	*%eax
.globl _objc_msgSend_stret
_objc_msgSend_stret:
   pushl	%ebp
	movl	%esp, %ebp
   movl 12(%ebp), %eax
   testl %eax, %eax
// nil receiver, go to workaround
   je stretNilReceiver

	subl	$16, %esp
	pushl	16(%ebp)
	pushl	12(%ebp)

   
	call	L_objc_msg_lookup$stub
	mov  %ebp, %esp
	pop  %ebp

	jmp	*%eax
   
stretNilReceiver:
// Modelled after what gcc outputs for a struct-return function
   pushl	%ebx
   call abiHack
abiHack:
	popl	%ebx
   popl	%ebx
   leave
   ret $4

.globl _objc_msgSendSuper_stret
_objc_msgSendSuper_stret:
	pushl	%ebp
	movl	%esp, %ebp
   pushl	%edi
   pushl %esi
	subl	$32, %esp
	movl	12(%ebp), %edi
	movl	16(%ebp), %esi
   movl	%esi, 4(%esp)
	movl	%edi, (%esp)
   call	L_objc_msg_lookup_super$stub
   movl  (%edi), %esi
	movl	%esi, 8(%ebp)
   
   addl  $32, %esp
   popl %esi
   popl %edi
   mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax

	.section __IMPORT,__jump_table,symbol_stubs,self_modifying_code+pure_instructions,5
L_objc_msg_lookup_super$stub:
	.indirect_symbol _objc_msg_lookup_super
	hlt ; hlt ; hlt ; hlt ; hlt
L_objc_msg_lookup$stub:
	.indirect_symbol _objc_msg_lookup
	hlt ; hlt ; hlt ; hlt ; hlt
	.subsections_via_symbols
   
