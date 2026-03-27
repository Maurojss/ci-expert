TCL_SCRIPT  = script.tcl
RELATORIO   = relatorio.txt
ORGANIZAR   = organizar.sh

all: $(RELATORIO) organizar

$(RELATORIO): $(TCL_SCRIPT)
	@echo "Gerando relatório..."
	tclsh $(TCL_SCRIPT)

organizar:
	@echo "Organizando projeto..."
	bash $(ORGANIZAR)

clean:
	rm -f $(RELATORIO)
	@echo "Relatório removido."

.PHONY: all organizar clean
