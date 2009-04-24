# Original - Christopher Lloyd <cjwl@objc.net>
.globl _objc_msg_sendv
_objc_msg_sendv:
	pushl	%ebp
	movl	%esp, %ebp
	pushl   %edx
	pushl   %ecx
	pushl	12(%ebp)
	pushl   8(%ebp)
	call	_objc_msg_lookup
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
    .section .drectve
    .ascii " -export:objc_msg_sendv"
