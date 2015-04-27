.globl _objc_msgSend_fpret
	.type	_objc_msgSend_fpret, @function
_objc_msgSend_fpret:

.globl _objc_msgSend
	.type	_objc_msgSend, @function
_objc_msgSend:

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
   
	pushq	%rbp
	movq	%rsp, %rbp
	pushq	%rsi
	pushq	%rbx
	movq	16(%rbp), %rsi     # self
	movq	24(%rbp), %rbx    # _cmd
	testq	%rsi, %rsi
	jne	L8                
	xorq	%rax, %rax        # self == nil, bail
	leaq	-16(%rbp), %rsp
	popq	%rbx
	popq	%rsi
	leave
	ret
L8:
	movq	(%rsi), %rax
	movq	%rbx, %rdx
	andq	$504, %rdx     # OBJCMethodCacheMask
	addq	64(%rax), %rdx
L11:
	movq	8(%rdx), %rax
	cmpq	%rbx, (%rax)
	jne	L9
	movq	16(%rax), %rax
	jmp	L10            # found selector in cache
L9:
	addq	(%rdx), %rdx
	jne	L11
	pushq	%rdx           # not in cache; traditional lookup
	pushq	%rdx
	pushq	%rbx
	pushq	%rsi
	call	OBJCInitializeLookupAndCacheUniqueIdForObject@PLT
	addq	$32, %rsp
L10:
	movq	%rbx, 24(%rbp)
	movq	%rsi, 16(%rbp)
	leaq	-16(%rbp), %rsp
	popq	%rbx
	popq	%rsi
	leave
	jmp	*%rax
   

.globl _objc_msgSendSuper
	.type	_objc_msgSendSuper, @function
_objc_msgSendSuper:
	pushq	%rbp
	movq	%rsp, %rbp
   pushq	%rdi
   pushq %rsi
	subq	$32, %rsp
	movq	16(%rbp), %rdi
	movq	24(%rbp), %rsi
   movq	%rsi, 8(%rsp)
	movq	%rdi, (%rsp)
   
	call	objc_msg_lookup_super@PLT

   movq  (%rdi), %rsi
	movq	%rsi, 16(%rbp)
   
   addq  $32, %rsp
   popq %rsi
   popq %rdi
   movq  %rbp, %rsp
	popq  %rbp
	jmp		*%rax   
	
	
.globl _objc_msgSend_stret
	.type	_objc_msgSend_stret, @function
_objc_msgSend_stret:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$64, %rsp
	pushq	32(%rbp)
	pushq	24(%rbp)
	call	objc_msg_lookup@PLT
	movq  %rbp, %rsp
	popq  %rbp
	jmp		*%rax

.globl _objc_msgSendSuper_stret
	.type	_objc_msgSendSuper_stret, @function
_objc_msgSendSuper_stret:
	pushq	%rbp
	movq	%rsp, %rbp
   pushq	%rdi
   pushq %rsi
	subq	$64, %rsp
	movq	24(%rbp), %rdi
	movq	32(%rbp), %rsi
   movq	%rsi, 8(%rsp)
	movq	%rdi, (%rsp)
   
	call	objc_msg_lookup_super@PLT

   movq  (%rdi), %rsi
	movq	%rsi, 16(%rbp)
   
   addq  $64, %rsp
   popq %rsi
   popq %rdi
   movq  %rbp, %rsp
	popq  %rbp
	jmp		*%rax

