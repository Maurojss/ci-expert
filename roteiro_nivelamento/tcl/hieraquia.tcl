# Script TCL - Tarefa 2: Hierarquia do Design
# Lê o arquivo netlist e gera árvore hierárquica

set filename "contador_netlist.tcl"
set f [open $filename r]
set content [read $f]
close $f

# Estruturas de dados
array set modules {}
array set instances {}

set current_module ""

# Parser linha a linha
foreach line [split $content "\n"] {
    set line [string trim $line]

    # Detecta início de módulo
    if {[regexp {^module\s+(\w+)\s*\(} $line match modname]} {
        set current_module $modname
        set modules($modname) 1
        set instances($modname) {}
    }

    # Detecta instância de submódulo (não é wire, input, output, always, etc.)
    if {$current_module ne "" && \
        [regexp {^(\w+)\s+(\w+)\s*\(} $line match celltype instname]} {

        # Ignora palavras-chave do Verilog
        set keywords {module input output wire reg always if else end assign}
        if {[lsearch $keywords $celltype] == -1} {
            # Verifica se é um módulo definido (não célula primitiva)
            lappend instances($current_module) $celltype
        }
    }
}

# Remove duplicatas e células primitivas conhecidas
set primitives {AND2 XOR2 OR2 NOT INV BUF NAND2 NOR2}

# Função para imprimir árvore
proc print_tree {modname indent} {
    global instances modules primitives

    puts "${indent}${modname}"

    if {![info exists instances($modname)]} {
        puts "${indent}  └─ (módulo não definido)"
        return
    }

    # Filtra instâncias únicas que são módulos definidos
    set sub_modules {}
    foreach inst $instances($modname) {
        if {[info exists modules($inst)] && [lsearch $sub_modules $inst] == -1} {
            lappend sub_modules $inst
        }
    }

    set has_primitives 0
    foreach inst $instances($modname) {
        if {[lsearch $primitives $inst] != -1} {
            set has_primitives 1
        }
    }

    if {[llength $sub_modules] == 0 && !$has_primitives} {
        puts "${indent}  └─ (módulo primitivo - sem submódulos)"
    } else {
        foreach sub $sub_modules {
            print_tree $sub "${indent}  ├─ "
        }
        if {$has_primitives} {
            puts "${indent}  └─ (células primitivas)"
        }
    }
}

# Exibe hierarquia
puts "\n=== HIERARQUIA DO DESIGN ===\n"
foreach mod [array names modules] {
    print_tree $mod ""
    puts ""
}
