#!/bin/bash

DRY_RUN=false
[ "$1" = "--dry-run" ] && DRY_RUN=true && echo "=== DRY-RUN ativo ==="

dirs_criados=0
arquivos_movidos=0

mover() {
    local f=$1 dest=$2

    if [ ! -d "$dest" ]; then
        $DRY_RUN && echo "[DRY] Criaria: $dest/" || { mkdir -p "$dest"; echo "Pasta criada: $dest/"; ((dirs_criados++)); }
    fi

    if [ -f "$dest/$(basename "$f")" ]; then
        echo "Pulando $f — já existe em $dest/"
        return
    fi

    $DRY_RUN && echo "[DRY] $f → $dest/" || { mv "$f" "$dest/"; echo "Movendo $f → $dest/"; ((arquivos_movidos++)); }
}

for f in *.v *.vh *.tcl *.do *.sh *.md *.txt; do
    [ -f "$f" ] || continue
    [ "$f" = "organizar.sh" ] && continue

    case "$f" in
        *_tb.v|*test)  mover "$f" tb      ;;
        *.vh)           mover "$f" include  ;;
        *.v)            mover "$f" src      ;;
        *.tcl|*.do|*.sh) mover "$f" scripts ;;
        *.md|*.txt)     mover "$f" docs    ;;
    esac
done

echo ""
echo "=== Relatório ==="
$DRY_RUN && echo "Dry-run: nada foi alterado" || echo "Pastas criadas: $dirs_criados | Arquivos movidos: $arquivos_movidos"
