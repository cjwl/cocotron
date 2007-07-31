	.section __TEXT,__text,regular,pure_instructions
	.section __TEXT,__picsymbolstub1,symbol_stubs,pure_instructions,32
	.machine ppc
	.text
	.align 2
	.globl _objc_msgSend
_objc_msgSend:
	mflr r0
	stmw r28,-16(r1)
	mr r29,r3
	mr r28,r4
	stw r0,8(r1)
	stwu r1,-80(r1)
	stw r5,112(r1)
	stw r6,116(r1)
	stw r7,120(r1)
	stw r8,124(r1)
	stw r9,128(r1)
	stw r10,132(r1)
	bl L_objc_msg_lookup$stub
   lwz r5,112(r1)
	lwz r6,116(r1)
	lwz r7,120(r1)
	lwz r8,124(r1)
	lwz r9,128(r1)
	lwz r10,132(r1)
	mr r12,r3
	mr r4,r28
	mr r3,r29
	mtctr r12
	bctrl
	addi r1,r1,80
	lwz r0,8(r1)
	lmw r28,-16(r1)
	mtlr r0
	blr
	.align 2
	.globl _objc_msgSendSuper
_objc_msgSendSuper:
	mflr r0
	stmw r28,-16(r1)
	mr r29,r3
	mr r28,r4
	stw r0,8(r1)
	stwu r1,-80(r1)
	stw r5,112(r1)
	stw r6,116(r1)
	stw r7,120(r1)
	stw r8,124(r1)
	stw r9,128(r1)
	stw r10,132(r1)
	bl L_objc_msg_lookup_super$stub
   lwz r5,112(r1)
	lwz r6,116(r1)
	lwz r7,120(r1)
	lwz r8,124(r1)
	lwz r9,128(r1)
	lwz r10,132(r1)
	mr r12,r3
	mr r4,r28
	lwz r3,0(r29)
	mtctr r12
	bctrl
	addi r1,r1,80
	lwz r0,8(r1)
	lmw r28,-16(r1)
	mtlr r0
	blr
	.align 2
	.globl _objc_msgSend_stret
_objc_msgSend_stret:
	mflr r0
	stmw r27,-20(r1)
	mr r28,r4
	mr r29,r3
	mr r4,r5
	mr r3,r28
	mr r27,r5
	stw r0,8(r1)
	stwu r1,-112(r1)
	stw r9,160(r1)
	stw r6,148(r1)
	stw r7,152(r1)
	stw r8,156(r1)
	stw r10,164(r1)
	bl L_objc_msg_lookup$stub
   lwz r9,160(r1)
	lwz r6,148(r1)
	lwz r7,152(r1)
	lwz r8,156(r1)
	lwz r10,164(r1)
	mr r4,r28
	mr r12,r3
	mr r5,r27
	addi r3,r1,64
	mtctr r12
	bctrl
	lwz r0,64(r1)
	lwz r2,68(r1)
	mr r3,r29
	lwz r9,72(r1)
	lwz r11,76(r1)
	addi r1,r1,112
	stw r0,0(r29)
	stw r2,4(r29)
	stw r9,8(r29)
	stw r11,12(r29)
	lwz r0,8(r1)
	nop
	lmw r27,-20(r1)
	mtlr r0
	blr
	.section __TEXT,__picsymbolstub1,symbol_stubs,pure_instructions,32
	.align 5
L_objc_msg_lookup_super$stub:
	.indirect_symbol _objc_msg_lookup_super
	mflr r0
	bcl 20,31,"L00000000001$spb"
"L00000000001$spb":
	mflr r11
	addis r11,r11,ha16(L_objc_msg_lookup_super$lazy_ptr-"L00000000001$spb")
	mtlr r0
	lwzu r12,lo16(L_objc_msg_lookup_super$lazy_ptr-"L00000000001$spb")(r11)
	mtctr r12
	bctr
	.lazy_symbol_pointer
L_objc_msg_lookup_super$lazy_ptr:
	.indirect_symbol _objc_msg_lookup_super
	.long	dyld_stub_binding_helper
	.section __TEXT,__picsymbolstub1,symbol_stubs,pure_instructions,32
	.align 5
L_objc_msg_lookup$stub:
	.indirect_symbol _objc_msg_lookup
	mflr r0
	bcl 20,31,"L00000000002$spb"
"L00000000002$spb":
	mflr r11
	addis r11,r11,ha16(L_objc_msg_lookup$lazy_ptr-"L00000000002$spb")
	mtlr r0
	lwzu r12,lo16(L_objc_msg_lookup$lazy_ptr-"L00000000002$spb")(r11)
	mtctr r12
	bctr
	.lazy_symbol_pointer
L_objc_msg_lookup$lazy_ptr:
	.indirect_symbol _objc_msg_lookup
	.long	dyld_stub_binding_helper
	.subsections_via_symbols
