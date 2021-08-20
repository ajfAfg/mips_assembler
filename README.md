# MipsAssembler

This repository implements a tiny subset of the MIPS assembler with pure Elixir.

## Quick Start

Run escript.

```bash
./mips_assembler foo.s
```

escript mips_assembler is placed to the top directory.

Note that you must have the Erlang VM installed in your environment to run escript.

## Opcodes

This MIPS assembler supports the following opcodes.

- Arithmetic Logic Unit

  - add
  - addi
  - addiu
  - addu
  - and
  - andi
  - nor
  - or
  - ori
  - slt
  - slti
  - sltiu
  - sltu
  - sub
  - subu
  - xor
  - xori

- Shifter

  - sll
  - sllv
  - sra
  - srav
  - srl
  - srlv

- Multiply

  - div
  - divu
  - mfhi
  - mflo
  - mthi
  - mtlo
  - mult
  - multu

- Branch

  - beq
  - bgez
  - bgtz
  - blez
  - bltz
  - bne
  - j
  - jal
  - jalr
  - jr

- Memory Access
  - lw
  - sw

## BNF

```EBNF
program = { stmt }, <EOF> ;

stmt = ws, stat, ws, ( <NEW_LINE> | <EOF> )
       | [ ws ], ( <NEW_LINE> | <EOF> );

stat = label, ws, instruction
     | label
     | instruction ;

label = identifier, ":" ;

instrution = op_code, ws, operand, [ ws, ",", ws, operand, [ ws, ",", ws, operand ] ]

op_code = identifier ;
operand = register
        | "(", ws, register, ws, ")"
        | addr_immd, ws, [ "(", ws, register, ws, ")" ]
        | identifier, ( ws | <NEW_LINE> | <EOF> ) ;

register = "$zero" | "$at" | "$v0" | "$v1" | "$v2"
         | "$a0" | "$a1" | "$a2" | "$a3"
         | "$t0" | "$t1" | "$t2" | "$t3" | "$t4" | "$t5" | "$t6" | "$t7" | "$t8" | "$t9"
         | "$s0" | "$s1" | "$s2" | "$s3" | "$s4" | "$s5" | "$s6" | "$s7"
         | "$k0" | "$k1" | "$gp" | "$sp" | "$fp" | "$ra" ;

addr_immd = [ "+" | "-" ], ws, { digit } ;

identifier = ( char | "_" ), { ( char | digit | "_" ) } ;

char = "A" | "B" | "C" | "D" | "E" | "F" | "G"
     | "H" | "I" | "J" | "K" | "L" | "M" | "N"
     | "O" | "P" | "Q" | "R" | "S" | "T" | "U"
     | "V" | "W" | "X" | "Y" | "Z" | "a" | "b"
     | "c" | "d" | "e" | "f" | "g" | "h" | "i"
     | "j" | "k" | "l" | "m" | "n" | "o" | "p"
     | "q" | "r" | "s" | "t" | "u" | "v" | "w"
     | "x" | "y" | "z" ;
digit = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;
ws = ? white_space characters ? ;
```

## Reference

- [BNF for MIPS](https://www.cse.iitd.ac.in/~nvkrishna/courses/winter07/grammar+spec/mips.html)
- [EBNF](https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form)
- [Opcodes](https://opencores.org/projects/plasma/opcodes)
