
.globl objc_msgSend_fpret
	.type	objc_msgSend_fpret, @function
objc_msgSend_fpret:

.globl objc_msgSend
	.type	objc_msgSend, @function
objc_msgSend:

/*
   # this just calls objc_msg_lookup, then jumps to the returned method
	pushl	%ebp
	movl	%esp, %ebp
	subl	$16, %esp
	pushl	12(%ebp)
	pushl	8(%ebp)
	call	objc_msg_lookup
	mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax
*/
   
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
	call	OBJCInitializeLookupAndCacheUniqueIdForObject
	addl	$16, %esp
	testl	%eax, %eax
	jne	L10
#ifdef HAVE_LIBFFI
	pushl	%eax           # not found at all; get forwarder
	pushl	%eax
	pushl	%ebx
	pushl	%esi
	call	objc_forward_ffi
	addl	$16, %esp
#else
   movl	$objc_msgForward, %eax  # non-libffi forwarder function
#endif
L10:
	movl	%ebx, 12(%ebp)
	movl	%esi, 8(%ebp)
	leal	-8(%ebp), %esp
	popl	%ebx
	popl	%esi
	leave
	jmp	*%eax
   

.globl objc_msgSendSuper
	.type	objc_msgSendSuper, @function
objc_msgSendSuper:
	pushl	%ebp
	movl	%esp, %ebp
   pushl	%edi
   pushl %esi
	subl	$16, %esp
	movl	8(%ebp), %edi
	movl	12(%ebp), %esi
   movl	%esi, 4(%esp)
	movl	%edi, (%esp)
   
	call	objc_msg_lookup_super

   movl  (%edi), %esi
	movl	%esi, 8(%ebp)
   
   addl  $16, %esp
   popl %esi
   popl %edi
   mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax   
	
	
.globl objc_msgSend_stret
	.type	objc_msgSend_stret, @function
objc_msgSend_stret:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$32, %esp
	pushl	16(%ebp)
	pushl	12(%ebp)
	call	objc_msg_lookup
	mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax

.globl objc_msgSendSuper_stret
	.type	objc_msgSendSuper_stret, @function
objc_msgSendSuper_stret:
	pushl	%ebp
	movl	%esp, %ebp
   pushl	%edi
   pushl %esi
	subl	$32, %esp
	movl	12(%ebp), %edi
	movl	16(%ebp), %esi
   movl	%esi, 4(%esp)
	movl	%edi, (%esp)
   
	call	objc_msg_lookup_super

   movl  (%edi), %esi
	movl	%esi, 8(%ebp)
   
   addl  $32, %esp
   popl %esi
   popl %edi
   mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax

.globl objc_msgSend_fpret
	.type	objc_msgSend_fpret, @function
objc_msgSend_fpret:

.globl objc_msgSend
	.type	objc_msgSend, @function
objc_msgSend:

/*
   # this just calls objc_msg_lookup, then jumps to the returned method
	pushl	%ebp
	movl	%esp, %ebp
	subl	$16, %esp
	pushl	12(%ebp)
	pushl	8(%ebp)
	call	objc_msg_lookup
	mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax
*/
   
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
	call	OBJCInitializeLookupAndCacheUniqueIdForObject
	addl	$16, %esp
	testl	%eax, %eax
	jne	L10
#ifdef HAVE_LIBFFI
	pushl	%eax           # not found at all; get forwarder
	pushl	%eax
	pushl	%ebx
	pushl	%esi
	call	objc_forward_ffi
	addl	$16, %esp
#else
   movl	$objc_msgForward, %eax  # non-libffi forwarder function
#endif
L10:
	movl	%ebx, 12(%ebp)
	movl	%esi, 8(%ebp)
	leal	-8(%ebp), %esp
	popl	%ebx
	popl	%esi
	leave
	jmp	*%eax
   

.globl objc_msgSendSuper
	.type	objc_msgSendSuper, @function
objc_msgSendSuper:
	pushl	%ebp
	movl	%esp, %ebp
   pushl	%edi
   pushl %esi
	subl	$16, %esp
	movl	8(%ebp), %edi
	movl	12(%ebp), %esi
   movl	%esi, 4(%esp)
	movl	%edi, (%esp)
   
	call	objc_msg_lookup_super

   movl  (%edi), %esi
	movl	%esi, 8(%ebp)
   
   addl  $16, %esp
   popl %esi
   popl %edi
   mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax   
	
	
.globl objc_msgSend_stret
	.type	objc_msgSend_stret, @function
objc_msgSend_stret:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$32, %esp
	pushl	16(%ebp)
	pushl	12(%ebp)
	call	objc_msg_lookup
	mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax

.globl objc_msgSendSuper_stret
	.type	objc_msgSendSuper_stret, @function
objc_msgSendSuper_stret:
	pushl	%ebp
	movl	%esp, %ebp
   pushl	%edi
   pushl %esi
	subl	$32, %esp
	movl	12(%ebp), %edi
	movl	16(%ebp), %esi
   movl	%esi, 4(%esp)
	movl	%edi, (%esp)
   
	call	objc_msg_lookup_super

   movl  (%edi), %esi
	movl	%esi, 8(%ebp)
   
   addl  $32, %esp
   popl %esi
   popl %edi
   mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax

.globl objc_msgSend_fpret
	.type	objc_msgSend_fpret, @function
objc_msgSend_fpret:

.globl objc_msgSend
	.type	objc_msgSend, @function
objc_msgSend:

/*
   # this just calls objc_msg_lookup, then jumps to the returned method
	pushl	%ebp
	movl	%esp, %ebp
	subl	$16, %esp
	pushl	12(%ebp)
	pushl	8(%ebp)
	call	objc_msg_lookup
	mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax
*/
   
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
	call	OBJCInitializeLookupAndCacheUniqueIdForObject
	addl	$16, %esp
	testl	%eax, %eax
	jne	L10
#ifdef HAVE_LIBFFI
	pushl	%eax           # not found at all; get forwarder
	pushl	%eax
	pushl	%ebx
	pushl	%esi
	call	objc_forward_ffi
	addl	$16, %esp
#else
   movl	$objc_msgForward, %eax  # non-libffi forwarder function
#endif
L10:
	movl	%ebx, 12(%ebp)
	movl	%esi, 8(%ebp)
	leal	-8(%ebp), %esp
	popl	%ebx
	popl	%esi
	leave
	jmp	*%eax
   

.globl objc_msgSendSuper
	.type	objc_msgSendSuper, @function
objc_msgSendSuper:
	pushl	%ebp
	movl	%esp, %ebp
   pushl	%edi
   pushl %esi
	subl	$16, %esp
	movl	8(%ebp), %edi
	movl	12(%ebp), %esi
   movl	%esi, 4(%esp)
	movl	%edi, (%esp)
   
	call	objc_msg_lookup_super

   movl  (%edi), %esi
	movl	%esi, 8(%ebp)
   
   addl  $16, %esp
   popl %esi
   popl %edi
   mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax   
	
	
.globl objc_msgSend_stret
	.type	objc_msgSend_stret, @function
objc_msgSend_stret:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$32, %esp
	pushl	16(%ebp)
	pushl	12(%ebp)
	call	objc_msg_lookup
	mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax

.globl objc_msgSendSuper_stret
	.type	objc_msgSendSuper_stret, @function
objc_msgSendSuper_stret:
	pushl	%ebp
	movl	%esp, %ebp
   pushl	%edi
   pushl %esi
	subl	$32, %esp
	movl	12(%ebp), %edi
	movl	16(%ebp), %esi
   movl	%esi, 4(%esp)
	movl	%edi, (%esp)
   
	call	objc_msg_lookup_super

   movl  (%edi), %esi
	movl	%esi, 8(%ebp)
   
   addl  $32, %esp
   popl %esi
   popl %edi
   mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax

.globl objc_msgSend_fpret
	.type	objc_msgSend_fpret, @function
objc_msgSend_fpret:

.globl objc_msgSend
	.type	objc_msgSend, @function
objc_msgSend:

/*
   # this just calls objc_msg_lookup, then jumps to the returned method
	pushl	%ebp
	movl	%esp, %ebp
	subl	$16, %esp
	pushl	12(%ebp)
	pushl	8(%ebp)
	call	objc_msg_lookup
	mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax
*/
   
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
	call	OBJCInitializeLookupAndCacheUniqueIdForObject
	addl	$16, %esp
	testl	%eax, %eax
	jne	L10
#ifdef HAVE_LIBFFI
	pushl	%eax           # not found at all; get forwarder
	pushl	%eax
	pushl	%ebx
	pushl	%esi
	call	objc_forward_ffi
	addl	$16, %esp
#else
   movl	$objc_msgForward, %eax  # non-libffi forwarder function
#endif
L10:
	movl	%ebx, 12(%ebp)
	movl	%esi, 8(%ebp)
	leal	-8(%ebp), %esp
	popl	%ebx
	popl	%esi
	leave
	jmp	*%eax
   

.globl objc_msgSendSuper
	.type	objc_msgSendSuper, @function
objc_msgSendSuper:
	pushl	%ebp
	movl	%esp, %ebp
   pushl	%edi
   pushl %esi
	subl	$16, %esp
	movl	8(%ebp), %edi
	movl	12(%ebp), %esi
   movl	%esi, 4(%esp)
	movl	%edi, (%esp)
   
	call	objc_msg_lookup_super

   movl  (%edi), %esi
	movl	%esi, 8(%ebp)
   
   addl  $16, %esp
   popl %esi
   popl %edi
   mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax   
	
	
.globl objc_msgSend_stret
	.type	objc_msgSend_stret, @function
objc_msgSend_stret:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$32, %esp
	pushl	16(%ebp)
	pushl	12(%ebp)
	call	objc_msg_lookup
	mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax

.globl objc_msgSendSuper_stret
	.type	objc_msgSendSuper_stret, @function
objc_msgSendSuper_stret:
	pushl	%ebp
	movl	%esp, %ebp
   pushl	%edi
   pushl %esi
	subl	$32, %esp
	movl	12(%ebp), %edi
	movl	16(%ebp), %esi
   movl	%esi, 4(%esp)
	movl	%edi, (%esp)
   
	call	objc_msg_lookup_super

   movl  (%edi), %esi
	movl	%esi, 8(%ebp)
   
   addl  $32, %esp
   popl %esi
   popl %edi
   mov  %ebp, %esp
	pop  %ebp
	jmp		*%eax
