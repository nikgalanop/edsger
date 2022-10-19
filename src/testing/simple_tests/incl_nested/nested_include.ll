; ModuleID = 'edsger-program'
source_filename = "edsger-program"

define i16 @g_i_0(i16 %z) {
entry:
  %z1 = alloca i16, align 2
  store i16 %z, i16* %z1, align 2
  %loadtmp = load i16, i16* %z1, align 2
  %multmp = mul i16 3, %loadtmp
  ret i16 %multmp
}

define i16 @f_ii_0(i16 %x, i16 %y) {
entry:
  %x1 = alloca i16, align 2
  store i16 %x, i16* %x1, align 2
  %y2 = alloca i16, align 2
  store i16 %y, i16* %y2, align 2
  %loadtmp = load i16, i16* %x1, align 2
  %calltmp = call i16 @g_i_0(i16 %loadtmp)
  %loadtmp3 = load i16, i16* %y2, align 2
  %calltmp4 = call i16 @g_i_0(i16 %loadtmp3)
  %addtmp = add i16 %calltmp, %calltmp4
  ret i16 %addtmp
}

define i16 @h_i_0(i16 %x) {
entry:
  %x1 = alloca i16, align 2
  store i16 %x, i16* %x1, align 2
  %loadtmp = load i16, i16* %x1, align 2
  %addtmp = add i16 %loadtmp, 23
  ret i16 %addtmp
}

declare void @writeInteger_i_0(i16)

declare void @writeBoolean_b_0(i1)

declare void @writeChar_c_0(i8)

declare void @writeReal_d_0(double)

declare void @writeString_c1_0(i8*)

declare i16 @readInteger__0()

declare i1 @readBoolean__0()

declare i8 @readChar__0()

declare double @readReal__0()

declare void @readString_ic1_0(i16, i8*)

define void @main() {
entry:
  %calltmp = call i16 @f_ii_0(i16 2, i16 3)
  %calltmp1 = call i16 @h_i_0(i16 %calltmp)
  call void @writeInteger_i_0(i16 %calltmp1)
  call void @writeChar_c_0(i8 10)
  ret void
}
