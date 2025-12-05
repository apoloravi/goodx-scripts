#!/bin/bash

# ===============================================
# SCRIPT: Extrair Filmes e Séries de lista M3U via URL
# AUTOR: Apolo Ravi / ChatGPT
# ===============================================

# ===== CONFIGURAÇÕES =====
URL="$1"
BASE_DIR="biblioteca"
TMP_M3U="temp_lista.m3u"

if [[ -z "$URL" ]]; then
    echo "Uso: ./processa.sh <URL_M3U>"
    exit 1
fi

# Criar pastas globais
mkdir -p "$BASE_DIR/filmes"
mkdir -p "$BASE_DIR/series"

echo "[⏳] Baixando lista..."
curl -s -L "$URL" -o "$TMP_M3U"

echo "[📂] Processando lista..."
while IFS= read -r line; do
    if [[ "$line" == \#EXTINF* ]]; then

        # Extrair categoria
        cat=$(echo "$line" | grep -oP 'group-title="\K[^"]+' | tr ' ' '_')
        [[ -z "$cat" ]] && cat="Sem_Categoria"

        # Extrair nome completo (filme/série/episódio)
        titulo=$(echo "$line" | sed -E 's/.*,(.*)/\1/' | tr '/' '-')

        # Ler link do vídeo
        read -r url_stream

        # ====== IGNORAR CANAIS ======
        if echo "$cat" | grep -qiE "CANAIS|TV|NEWS|SPORT|ESPN|PREMIERE|HBO|GLOBO|BAND|CNN"; then
            continue
        fi

        # ====== TRATAR FILMES ======
        if echo "$cat" | grep -qiE "FILME|MOVIE|CINEMA|MEGAPIX|ACTION|DRAMA|TERROR|AVENTURA|COMEDIA"; then
            mkdir -p "$BASE_DIR/filmes/$cat"

            nome_filme=$(echo "$titulo" | sed 's/[^A-Za-z0-9._-]/_/g')

            echo "$url_stream" > "$BASE_DIR/filmes/$cat/$nome_filme.mp4"

            echo "  🎬 Filme: $cat / $nome_filme"
            continue
        fi

        # ====== TRATAR SÉRIES ======
        if echo "$cat" | grep -qiE "SERIE|SÉRIE|SHOW|EPISOD|NOVELA|TEMPORADA"; then

            mkdir -p "$BASE_DIR/series/$cat"

            # Extrair nome da série e temporada/episódio
            nome=$(echo "$titulo" | sed -E 's/[sS]([0-9]{1,2})[eE].*//; s/[tT]([0-9]{1,2})[eE].*//; s/[^A-Za-z0-9]/_/g')

            # Detectar temporada
            tp=$(echo "$titulo" | grep -oEi '([sS]|[tT])(0?[0-9]{1,2})' | grep -oEi '[0-9]{1,2}')
            tp=$(printf "%02d" "$tp" 2>/dev/null)
            [[ -z "$tp" ]] && tp="01"

            # Detectar episódio
            ep=$(echo "$titulo" | grep -oEi '[eE][0-9]{1,2}' | grep -oEi '[0-9]{1,2}')
            ep=$(printf "%02d" "$ep" 2>/dev/null)
            [[ -z "$ep" ]] && ep="01"

            serie_path="$BASE_DIR/series/$cat/$nome/tp$tp"
            mkdir -p "$serie_path"

            arq="$serie_path/ep$ep.mp4"

            echo "$url_stream" > "$arq"

            echo "  📺 Série: $cat / $nome / TP$tp / EP$ep"

        fi

    fi
done < "$TMP_M3U"


echo ""
echo "[✔] Processamento concluído!"
echo "Arquivos organizados dentro da pasta: $BASE_DIR/"
