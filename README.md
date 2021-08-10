# MipsAssembler

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `mips_assembler` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mips_assembler, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/mips_assembler](https://hexdocs.pm/mips_assembler).

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

op_code = "add" | "sub" | "mult" | "div" | "addi"
        | "addu" | "subu" | "multu" | "divu" | "addiu"
        | "and" | "or" | "nor" | "xor" | "andi" | "ori" | "xori"
        | "sll" | "srl" | "sllv" | "srlv" | "sra" | "srav"
        | "lw" | "sw" | "mfhi" | "mflo" | "mthi" | "mtlo"
        | "slt" | "sltu" | "slti" | "sltiu"
        | "beq" | "bne" | "bgez" | "bgtz" | "blez" | "bltz"
        | "j" | "jal" | "jr" | "jalr" ;
operand = register
        | "(", ws, register, ws, ")"
        | addr_immd, ws, [ "(", ws, register, ws, ")" ]
        | identifier, ( ws | <NEW_LINE> | word_end ) ;

register = "$zero" | "$at" | "$v0" | "$v1" | "$v2"
         | "$a0" | "$a1" | "$a2" | "$a3"
         | "$t0" | "$t1" | "$t2" | "$t3" | "$t4" | "$t5" | "$t6" | "$t7" | "$t8" | "$t9"
         | "$s0" | "$s1" | "$s2" | "$s3" | "$s4" | "$s5" | "$s6" | "$s7"
         | "$k0" | "$k1" | "$gp" | "$sp" | "$fp" | "$ra" ;

addr_immd = [ "+" | "-" ], ws, { digit } ;

identifier = ( char | "_" ), { ( char | digit | "_" ) } ;

word_end = "" ;

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

[BNF for MIPS](https://www.cse.iitd.ac.in/~nvkrishna/courses/winter07/grammar+spec/mips.html)
[EBNF](https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form)
