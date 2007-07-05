	.text
.globl _objc_msgSend
_objc_msgSend:
	pushl	%ebp
	movl	%esp, %ebp
	pushl	%edi
	pushl	%esi
	subl	$16, %esp
	movl	8(%ebp), %edi
	movl	12(%ebp), %esi
	movl	%esi, 4(%esp)
	movl	%edi, (%esp)
	call	L_objc_msg_lookup$stub
    popl    %esi
    popl    %edi
	jmp	*%eax
.globl _objc_msgSendSuper
_objc_msgSendSuper:
	pushl	%ebp
	movl	%esp, %ebp
	pushl	%edi
	pushl	%esi
	subl	$16, %esp
	movl	8(%ebp), %edi
	movl	12(%ebp), %esi
	movl	%esi, 4(%esp)
	movl	%edi, (%esp)
	call	L_objc_msg_lookup_super$stub
    popl    %esi
    popl    %edi
	jmp	*%eax
.globl _objc_msgSend_fpret
_objc_msgSend_fpret:
	pushl	%ebp
	movl	%esp, %ebp
	pushl	%edi
	pushl	%esi
	subl	$16, %esp
	movl	8(%ebp), %edi
	movl	12(%ebp), %esi
	movl	%esi, 4(%esp)
	movl	%edi, (%esp)
	call	L_objc_msg_lookup$stub
    popl    %esi
    popl    %edi
	jmp	*%eax
.globl _objc_msgSend_stret
_objc_msgSend_stret:
	pushl	%ebp
	movl	%esp, %ebp
	pushl	%edi
	pushl	%esi
	subl	$32, %esp
	movl	8(%ebp), %esi
	movl	16(%ebp), %edi
	movl	%edi, 4(%esp)
	movl	12(%ebp), %eax
	movl	%eax, (%esp)
	call	L_objc_msg_lookup$stub
    popl    %esi
    popl    %edi
	jmp	*%eax
	.section __IMPORT,__jump_table,symbol_stubs,self_modifying_code+pure_instructions,5
L_objc_msg_lookup_super$stub:
	.indirect_symbol _objc_msg_lookup_super
	hlt ; hlt ; hlt ; hlt ; hlt
L_objc_msg_lookup$stub:
	.indirect_symbol _objc_msg_lookup
	hlt ; hlt ; hlt ; hlt ; hlt
	.subsections_via_symbols
