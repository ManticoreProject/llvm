; REQUIRES: x86-registered-target
; RUN: llc < %s -march=x86-64 | FileCheck %s

;; Regression testing for the C_SHIM calling convention.

declare cc98 i64 @doCCall_1 (i64*, i64 (i64, i64)*, i64, i64)
declare cc98 float @doCCall_2 (i64*, float (float, float)*, float, float)

declare x86_64_sysvcc i64 @func1 (i64, i64)
declare x86_64_sysvcc float @func2 (float, float)


define x86_64_sysvcc i64 @test1(i64* %vp, i64 %x, i64 %y, i64 %liveAfter) {
;; vp -> rdi, x -> rsi, y -> rdx, liveAfter -> rcx

;; check argument setup

; CHECK-LABEL: test1
; CHECK: movq    %rcx, %rbx
; CHECK: movq    _func1@GOTPCREL(%rip), %r10
; CHECK: movq    %rdi, %r11
; CHECK: movq    %rsi, %rdi
; CHECK: movq    %rdx, %rsi
	%rv1 = call cc98 i64 @doCCall_1(i64* %vp, i64 (i64, i64)* @func1, i64 %x, i64 %y)

;; check return

; CHECK: addq    %rbx, %rax
	%rv2 = add i64 %rv1, %liveAfter

	ret i64 %rv2
}

define x86_64_sysvcc float @test2(i64* %vp, float %x, float %y) {
;; vp -> rdi, x -> xmm0, y -> xmm1 

;; check argument setup. 

;; we exclude any movement of xmm registers before
;; the call with this sequence of check-next's

; CHECK-LABEL: test2
; CHECK:        pushq   %rax
; CHECK-NEXT:   .cfi_def_cfa_offset 16
; CHECK-NEXT:   movq    _func2@GOTPCREL(%rip), %r10
; CHECK-NEXT:   movq    %rdi, %r11
; CHECK-NEXT:   callq	_doCCall_2
; CHECK-NEXT:   addss	{{.*}}, %xmm0

	%rv1 = call cc98 float @doCCall_2(i64* %vp, float (float, float)* @func2, float %x, float %y)
	%rv2 = fadd float %rv1, 1.0
	ret float %rv2
}
