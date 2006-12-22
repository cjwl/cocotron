# Original - Christopher Lloyd <cjwl@objc.net>
.globl objc_msg_sendv
	.type	objc_msg_sendv, @function
objc_msg_sendv:
	pushl	%ebp
	movl	%esp, %ebp
	pushl   %edx
	pushl   %ecx
	pushl	12(%ebp)
	pushl   8(%ebp)
	call	objc_msg_lookup
	movl 16(%ebp),%ecx # ecx=argumentFrameByteSize
	movl 20(%ebp),%edx # edx=argumentFrame
pushNext:
	subl $4,%ecx       # argumentFrameByteSize-=sizeof(int)
	cmpl $4,%ecx       # check if we're at _cmd in argumentFrame
	jle done
	pushl (%edx,%ecx)
	jmp pushNext
done:
	pushl 12(%ebp) # push _cmd
	pushl 8(%ebp)  # push self
	call *%eax
	popl %ecx
	popl %edx
	leave
	ret
	.size	objc_msg_sendv, .-objc_msg_sendv
	.ident	"GCC: (GNU) 3.3.2"
