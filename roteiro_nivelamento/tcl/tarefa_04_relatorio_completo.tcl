set fp [open "netlist.v" r]
set conteudo [read $fp]
close $fp

set ignorar {module always if else for while reg wire input output inout assign parameter begin end endmodule}

# -------------------------------------------------------
# TAREFA 1 - Contagem de células
# -------------------------------------------------------
array set contagem {}

foreach {match nome_modulo} [regexp -all -inline {([a-zA-Z_]\w*)\s+[a-zA-Z_]\w*\s*\(} $conteudo] {
	if {$nome_modulo ni $ignorar} {
		incr contagem($nome_modulo)
	}
}

set total 0
foreach tipo [array names contagem] {
	incr total $contagem($tipo)
}

puts "\n=== RELATÓRIO DE CÉLULAS ==="
parray contagem
puts "TOTAL: $total instâncias"

# -------------------------------------------------------
# TAREFA 2 - Hierarquia do design
# -------------------------------------------------------
set modulos_definidos [regexp -all -inline {module\s+(\w+)} $conteudo]
set nomes_modulos {}
foreach {match nome} $modulos_definidos {
    lappend nomes_modulos $nome
}

puts "\n=== HIERARQUIA DO DESIGN ==="

foreach nome $nomes_modulos {
    regexp "module\\s+${nome}\\s*\\(.*?endmodule" $conteudo bloco

    array set filhos {}
    foreach {match tipo} [regexp -all -inline {([a-zA-Z_]\w*)\s+[a-zA-Z_]\w*\s*\(} $bloco] {
        if {$tipo ni $ignorar && $tipo ne $nome} {
            incr filhos($tipo)
        }
    }

    puts "\n$nome"
    if {[array size filhos] == 0} {
        puts "  └── (módulo primitivo - sem instâncias internas)"
    } else {
        foreach tipo [array names filhos] {
            puts "  ├── $tipo ($filhos($tipo) instâncias)"
        }
    }
    array unset filhos
}

# -------------------------------------------------------
# TAREFA 3 - Fanout das nets
# -------------------------------------------------------
array set fanout {}

foreach {match net} [regexp -all -inline {\.(?:y|Q)\((\w[\w\[\]]*)\)} $conteudo] {
    if {![info exists fanout($net)]} {
        set fanout($net) 0
    }
}

foreach {match net} [regexp -all -inline {\.(?:a|b|D|clk|rst)\((\w[\w\[\]]*)\)} $conteudo] {
    if {[string match "*'b*" $net]} continue
    if {[info exists fanout($net)]} {
        incr fanout($net)
    }
}

set pares {}
foreach net [array names fanout] {
    lappend pares [list $net $fanout($net)]
}
set pares [lsort -decreasing -integer -index 1 $pares]

puts "\n=== TOP 10 NETS POR FANOUT ==="
set i 0
foreach par $pares {
    if {$i >= 10} break
    puts "  [lindex $par 0]: fanout = [lindex $par 1]"
    incr i
}

puts "\n=== NETS COM FANOUT ZERO (POSSÍVEIS ERROS) ==="
set erros 0
foreach par $pares {
    if {[lindex $par 1] == 0} {
        puts "  AVISO: '[lindex $par 0]' nunca usada como entrada"
        incr erros
    }
}
if {$erros == 0} { puts "  Nenhum problema encontrado." }
