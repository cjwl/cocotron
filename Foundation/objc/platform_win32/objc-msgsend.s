
.globl _objc_msgSend
	.def	_objc_msgSend;	.scl	2;	.type	32;	.endef
_objc_msgSend:
	pushl	%ebp
	movl	%esp, %ebp
	pushl	%esi
	pushl	%ebx
	movl	8(%ebp), %esi     # self
	movl	12(%ebp), %ebx    # _cmd
	testl	%esi, %esi
	jne	L8                
	xorl	%eax, %eax        # self == nil, bail
	leal	-8(%ebp), %esp
	popl	%ebx
	popl	%esi
	leave
	ret
L8:
	movl	(%esi), %eax
	movl	%ebx, %edx
	andl	$504, %edx     # OBJCMethodCacheMask
	addl	32(%eax), %edx
L11:
	movl	4(%edx), %eax
	cmpl	%ebx, (%eax)
	jne	L9
	movl	8(%eax), %eax
	jmp	L10            # found selector in cache
L9:
	addl	(%edx), %edx
	jne	L11
	pushl	%edx           # not in cache; traditional lookup
	pushl	%edx
	pushl	%ebx
	pushl	%esi
	call	_OBJCInitializeLookupAndCacheUniqueIdForObject
	addl	$16, %esp
	testl	%eax, %eax
	jne	L10
#ifdef HAVE_LIBFFI
	pushl	%eax           # not found at all; get forwarder
	pushl	%eax
	pushl	%ebx
	pushl	%esi
	call	_objc_forward_ffi
	addl	$16, %esp
#else
   movl	$_objc_msgForward, %eax  # non-libffi forwarder function
#endif
L10:
	movl	%ebx, 12(%ebp)
	movl	%esi, 8(%ebp)
	leal	-8(%ebp), %esp
	popl	%ebx
	popl	%esi
	leave
	jmp	*%eax
   

.globl _objc_msgSendSuper
	.def	_objc_msgSendSuper;	.scl	2;	.type	32;	.endef
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
   
	call	_objc_msg_lookup_super

   movl  (%edi), %esi
	movl	%esi, 8(%ebp)
   
   addl  $16, %esp
   popl %esi
   popl %edi
   mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax   
	
	
.globl _objc_msgSend_stret
	.def	_objc_msgSend_stret;	.scl	2;	.type	32;	.endef
_objc_msgSend_stret:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$32, %esp
	pushl	16(%ebp)
	pushl	12(%ebp)
	call	_objc_msg_lookup
	mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax
   
