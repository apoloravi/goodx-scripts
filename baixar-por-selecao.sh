#!/bin/bash

# ===============================================
# SCRIPT: Analisador Rápido de Filmes/Séries
# Versão otimizada para listas grandes
# ===============================================

# ===== CONFIGURAÇÕES =====
BASE_DIR="biblioteca"
TMP_M3U="temp_lista.m3u"
ANALISE_FILE="analise.txt"
LOG_FILE="baixados.log"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Função para mostrar banner
mostrar_banner() {
    clear
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${CYAN}    🎬 ANALISADOR RÁPIDO IPTV 🎬         ${NC}"
    echo -e "${CYAN}==========================================${NC}"
    echo ""
}

# Função para pedir URL
pedir_url() {
    echo -e "${YELLOW}🔗 COLE A URL DA SUA LISTA M3U:${NC}"
    echo -e "${BLUE}Exemplo: http://need01.fun/get.php?username=XXXX&password=XXXX&type=m3u_plus${NC}"
    echo ""
    read -p "URL: " URL
    
    if [[ -z "$URL" ]]; then
        echo -e "${RED}[❌] URL não fornecida!${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}[✅] URL recebida!${NC}"
    echo ""
}

# Função para extrair categoria
extrair_categoria() {
    echo "$1" | grep -o 'group-title="[^"]*"' | cut -d'"' -f2
}

# Função para extrair título
extrair_titulo() {
    echo "$1" | sed 's/.*,//'
}

# Função para mostrar progresso
mostrar_progresso() {
    local atual="$1"
    local total="$2"
    local percentual=$((atual * 100 / total))
    local barras=$((percentual / 2))
    
    printf "\r["
    for ((i=0; i<50; i++)); do
        if [[ $i -lt $barras ]]; then
            printf "▓"
        else
            printf "░"
        fi
    done
    printf "] %3d%% (%d/%d)" $percentual $atual $total
}

# Função para análise rápida
analise_rapida() {
    echo -e "${CYAN}[1/3] 📊 ANALISANDO CONTEÚDO (MODO RÁPIDO)...${NC}"
    echo ""
    
    # Baixar apenas o início da lista para análise
    echo -e "${YELLOW}📥 Baixando amostra da lista (primeiros 50.000 itens)...${NC}"
    curl -s -L "$URL" | head -100000 > "$TMP_M3U" 2>/dev/null
    
    if [[ ! -s "$TMP_M3U" ]]; then
        echo -e "${RED}❌ Erro ao baixar lista M3U${NC}"
        exit 1
    fi
    
    total_linhas=$(wc -l < "$TMP_M3U")
    echo -e "${GREEN}✅ Amostra baixada: $total_linhas linhas${NC}"
    
    # Arrays para categorias
    declare -A categorias_filmes
    declare -A categorias_series
    
    # Contadores
    total_itens=0
    filmes=0
    series=0
    canais=0
    
    echo ""
    echo -e "${YELLOW}🔍 Analisando amostra...${NC}"
    echo ""
    
    # Ler arquivo linha por linha
    linha_num=0
    while IFS= read -r linha || [[ -n "$linha" ]]; do
        ((linha_num++))
        
        # Mostrar progresso a cada 1000 linhas
        if [[ $((linha_num % 1000)) -eq 0 ]]; then
            mostrar_progresso $linha_num $total_linhas
        fi
        
        # Pular cabeçalhos
        if [[ "$linha" == \#EXTM3U* ]] || [[ "$linha" == \#EXT-X-SESSION-DATA* ]]; then
            continue
        fi
        
        # Linha EXTINF
        if [[ "$linha" == \#EXTINF:* ]]; then
            # Ler próxima linha (URL)
            read -r url
            
            ((total_itens++))
            
            # Ignorar canais (.ts, .m3u8)
            if [[ "$url" == *.ts ]] || [[ "$url" == *.m3u8 ]]; then
                ((canais++))
                continue
            fi
            
            # Extrair categoria
            categoria=$(extrair_categoria "$linha")
            categoria=$(echo "$categoria" | sed '
                s/^SÉRIES[[:space:]]*|[[:space:]]*//;
                s/^Filmes[[:space:]]*|[[:space:]]*//;
                s/^[^a-zA-Z0-9]*//;
            ')
            
            [[ -z "$categoria" ]] && categoria="Sem_Categoria"
            
            # Extrair título
            titulo=$(extrair_titulo "$linha")
            
            # Verificar se é série
            is_serie=0
            if [[ "$titulo" =~ [Ss][0-9]{1,2}[Ee][0-9]{1,2} ]] || 
               [[ "$titulo" =~ [0-9]{1,2}[Xx][0-9]{1,2} ]] ||
               [[ "$url" == */series/* ]]; then
                is_serie=1
            fi
            
            if [[ $is_serie -eq 1 ]]; then
                ((series++))
                if [[ -z "${categorias_series[$categoria]}" ]]; then
                    categorias_series["$categoria"]=1
                else
                    categorias_series["$categoria"]=$((categorias_series["$categoria"] + 1))
                fi
            else
                ((filmes++))
                if [[ -z "${categorias_filmes[$categoria]}" ]]; then
                    categorias_filmes["$categoria"]=1
                else
                    categorias_filmes["$categoria"]=$((categorias_filmes["$categoria"] + 1))
                fi
            fi
        fi
    done < "$TMP_M3U"
    
    printf "\r%-60s\n" "[==================================================] 100%"
    
    # Salvar análise
    echo "===== ANÁLISE RÁPIDA DO CONTEÚDO =====" > "$ANALISE_FILE"
    echo "Data: $(date)" >> "$ANALISE_FILE"
    echo "Amostra analisada: $total_itens itens" >> "$ANALISE_FILE"
    echo "" >> "$ANALISE_FILE"
    
    # Estimar totais (baseado na amostra)
    echo -e "${PURPLE}📊 ESTIMATIVAS BASEADAS NA AMOSTRA:${NC}"
    echo -e "${PURPLE}===================================${NC}"
    echo -e "${CYAN}📋 Itens na amostra:${NC} $total_itens"
    echo -e "${GREEN}🎬 Filmes estimados:${NC} $filmes"
    echo -e "${GREEN}📺 Séries estimadas:${NC} $series"
    echo -e "${RED}🚫 Canais ignorados:${NC} $canais"
    echo ""
    
    # Mostrar top categorias
    echo -e "${YELLOW}🎬 TOP CATEGORIAS DE FILMES:${NC}"
    echo -e "${YELLOW}============================${NC}"
    i=1
    for categoria in "${!categorias_filmes[@]}"; do
        quantidade=${categorias_filmes[$categoria]}
        echo -e "${BLUE}$i. $categoria:${NC} $quantidade"
        echo "$i. $categoria: $quantidade" >> "$ANALISE_FILE"
        ((i++))
        [[ $i -gt 10 ]] && break
    done
    
    echo ""
    echo -e "${YELLOW}📺 TOP CATEGORIAS DE SÉRIES:${NC}"
    echo -e "${YELLOW}============================${NC}"
    for categoria in "${!categorias_series[@]}"; do
        quantidade=${categorias_series[$categoria]}
        echo -e "${BLUE}$i. $categoria:${NC} $quantidade"
        echo "$i. $categoria: $quantidade" >> "$ANALISE_FILE"
        ((i++))
        [[ $i -gt 20 ]] && break
    done
    
    echo ""
    echo -e "${GREEN}📄 Análise salva em: $ANALISE_FILE${NC}"
}

# Função para escolher o que baixar
escolher_download() {
    echo ""
    echo -e "${CYAN}[2/3] 🎯 ESCOLHA O QUE BAIXAR${NC}"
    echo -e "${CYAN}============================${NC}"
    echo ""
    
    # Ler categorias do arquivo de análise
    echo -e "${YELLOW}Categorias disponíveis:${NC}"
    echo ""
    
    categorias=()
    while IFS= read -r linha; do
        if [[ "$linha" =~ ^[0-9]+\. ]]; then
            categorias+=("$linha")
            echo "$linha"
        fi
    done < "$ANALISE_FILE"
    
    echo ""
    echo -e "${PURPLE}Opções:${NC}"
    echo "1. 📥 Baixar TODOS os filmes e séries"
    echo "2. 🎬 Baixar apenas FILMES"
    echo "3. 📺 Baixar apenas SÉRIES"
    echo "4. 🔢 Escolher pelos números das categorias"
    echo "5. ❌ Sair"
    echo ""
    
    read -p "Escolha (1-5): " opcao
    
    case $opcao in
        1)
            echo -e "${GREEN}✅ Baixando tudo...${NC}"
            modo="tudo"
            ;;
        2)
            echo -e "${GREEN}✅ Baixando apenas filmes...${NC}"
            modo="filmes"
            ;;
        3)
            echo -e "${GREEN}✅ Baixando apenas séries...${NC}"
            modo="series"
            ;;
        4)
            echo ""
            echo -e "${YELLOW}Digite os números das categorias (ex: 1,3,5):${NC}"
            read -p "Categorias: " categorias_escolhidas
            modo="categorias"
            ;;
        5)
            echo -e "${YELLOW}👋 Saindo...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opção inválida!${NC}"
            escolher_download
            ;;
    esac
}

# Função para download direcionado
download_direcionado() {
    echo ""
    echo -e "${CYAN}[3/3] ⚡ DOWNLOAD DIRECIONADO${NC}"
    echo -e "${CYAN}============================${NC}"
    echo ""
    
    echo -e "${YELLOW}ℹ️  Este modo baixa diretamente, sem análise completa.${NC}"
    echo -e "${YELLOW}Escolha uma opção:${NC}"
    echo ""
    echo "1. ⚡ Baixar RÁPIDO (apenas primeiros 100 itens de cada tipo)"
    echo "2. 🐢 Baixar COMPLETO (pode demorar muito)"
    echo "3. ↩️  Voltar"
    echo ""
    
    read -p "Escolha (1-3): " velocidade
    
    case $velocidade in
        1)
            limite=100
            echo -e "${GREEN}⚡ Modo RÁPIDO ativado (max 100 itens por tipo)${NC}"
            ;;
        2)
            limite=999999
            echo -e "${YELLOW}🐢 Modo COMPLETO ativado (pode demorar horas)${NC}"
            ;;
        3)
            return
            ;;
        *)
            echo -e "${RED}❌ Opção inválida!${NC}"
            download_direcionado
            return
            ;;
    esac
    
    # Criar pastas
    mkdir -p "$BASE_DIR/filmes"
    mkdir -p "$BASE_DIR/series"
    
    # Iniciar log
    echo "===== DOWNLOAD DIRECIONADO =====" > "$LOG_FILE"
    echo "Data: $(date)" >> "$LOG_FILE"
    echo "Modo: $modo" >> "$LOG_FILE"
    echo "Limite: $limite" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    # Contadores
    filmes_baixados=0
    series_baixadas=0
    total_baixado=0
    
    echo ""
    echo -e "${YELLOW}📥 Iniciando downloads...${NC}"
    echo ""
    
    # Baixar lista completa
    echo -e "${BLUE}⏳ Baixando lista completa...${NC}"
    curl -s -L "$URL" -o "$TMP_M3U.full"
    
    if [[ ! -s "$TMP_M3U.full" ]]; then
        echo -e "${RED}❌ Erro ao baixar lista completa${NC}"
        return
    fi
    
    # Processar
    echo -e "${BLUE}🔍 Processando...${NC}"
    
    # Usar grep para extrair apenas .mp4 e processar mais rápido
    grep -A1 "\.mp4" "$TMP_M3U.full" | while IFS= read -r linha; do
        # Linha EXTINF
        if [[ "$linha" == \#EXTINF:* ]]; then
            titulo=$(echo "$linha" | sed 's/.*,//')
            categoria=$(echo "$linha" | grep -o 'group-title="[^"]*"' | cut -d'"' -f2)
            categoria=$(echo "$categoria" | sed '
                s/^SÉRIES[[:space:]]*|[[:space:]]*//;
                s/^Filmes[[:space:]]*|[[:space:]]*//;
                s/^[^a-zA-Z0-9]*//;
            ')
            [[ -z "$categoria" ]] && categoria="Sem_Categoria"
            
            # Ler URL
            read -r url
            
            # Verificar limites
            if [[ "$modo" == "filmes" ]] && [[ "$titulo" =~ [Ss][0-9]{1,2}[Ee][0-9]{1,2} ]]; then
                continue
            fi
            
            if [[ "$modo" == "series" ]] && ! [[ "$titulo" =~ [Ss][0-9]{1,2}[Ee][0-9]{1,2} ]]; then
                continue
            fi
            
            if [[ "$filmes_baixados" -ge $limite ]] && [[ "$series_baixadas" -ge $limite ]]; then
                break
            fi
            
            # Processar série
            if [[ "$titulo" =~ [Ss][0-9]{1,2}[Ee][0-9]{1,2} ]]; then
                if [[ "$series_baixadas" -ge $limite ]]; then
                    continue
                fi
                
                # Extrair informações
                if [[ "$titulo" =~ [Ss]([0-9]{1,2})[Ee]([0-9]{1,2}) ]]; then
                    temporada="${BASH_REMATCH[1]}"
                    episodio="${BASH_REMATCH[2]}"
                    nome_serie=$(echo "$titulo" | sed 's/[Ss][0-9]\{1,2\}[Ee][0-9]\{1,2\}.*//')
                else
                    temporada="01"
                    episodio="01"
                    nome_serie="$titulo"
                fi
                
                temporada=$(printf "%02d" "$temporada" 2>/dev/null || echo "01")
                episodio=$(printf "%02d" "$episodio" 2>/dev/null || echo "01")
                
                # Limpar nomes
                nome_serie=$(echo "$nome_serie" | sed 's/[<>:"/\\|?*]/_/g; s/  */_/g')
                categoria=$(echo "$categoria" | sed 's/[<>:"/\\|?*]/_/g; s/  */_/g')
                
                # Criar estrutura
                mkdir -p "$BASE_DIR/series/$categoria/$nome_serie/tp$temporada"
                destino="$BASE_DIR/series/$categoria/$nome_serie/tp$temporada/ep$episodio.mp4"
                
                if [[ ! -f "$destino" ]]; then
                    echo -e "${BLUE}📥 Série: $nome_serie S${temporada}E${episodio}${NC}"
                    wget -q -O "$destino" "$url" 2>> "$LOG_FILE"
                    if [[ $? -eq 0 ]]; then
                        echo -e "${GREEN}✅ Baixado${NC}"
                        ((series_baixadas++))
                        ((total_baixado++))
                    fi
                else
                    echo -e "${BLUE}📁 Já existe: $nome_serie S${temporada}E${episodio}${NC}"
                    ((series_baixadas++))
                    ((total_baixado++))
                fi
                
            else
                # Processar filme
                if [[ "$filmes_baixados" -ge $limite ]]; then
                    continue
                fi
                
                # Limpar nomes
                nome_filme=$(echo "$titulo" | sed 's/[<>:"/\\|?*]/_/g; s/  */_/g')
                categoria=$(echo "$categoria" | sed 's/[<>:"/\\|?*]/_/g; s/  */_/g')
                
                # Criar estrutura
                mkdir -p "$BASE_DIR/filmes/$categoria"
                destino="$BASE_DIR/filmes/$categoria/$nome_filme.mp4"
                
                if [[ ! -f "$destino" ]]; then
                    echo -e "${BLUE}📥 Filme: $nome_filme${NC}"
                    wget -q -O "$destino" "$url" 2>> "$LOG_FILE"
                    if [[ $? -eq 0 ]]; then
                        echo -e "${GREEN}✅ Baixado${NC}"
                        ((filmes_baixados++))
                        ((total_baixado++))
                    fi
                else
                    echo -e "${BLUE}📁 Já existe: $nome_filme${NC}"
                    ((filmes_baixados++))
                    ((total_baixado++))
                fi
            fi
        fi
    done < <(grep -B1 "\.mp4" "$TMP_M3U.full")
    
    # Limpar
    rm -f "$TMP_M3U.full"
    
    # Relatório
    echo ""
    echo -e "${PURPLE}==========================================${NC}"
    echo -e "${PURPLE}           📊 DOWNLOAD CONCLUÍDO         ${NC}"
    echo -e "${PURPLE}==========================================${NC}"
    echo ""
    echo -e "${GREEN}🎬 Filmes baixados: $filmes_baixados${NC}"
    echo -e "${GREEN}📺 Séries baixadas: $series_baixadas${NC}"
    echo -e "${GREEN}📥 Total: $total_baixado arquivos${NC}"
    echo ""
    echo -e "${YELLOW}📁 Pasta dos filmes: $BASE_DIR/filmes/${NC}"
    echo -e "${YELLOW}📁 Pasta das séries: $BASE_DIR/series/${NC}"
    echo ""
    echo -e "${BLUE}📝 Log: $LOG_FILE${NC}"
    echo -e "${PURPLE}==========================================${NC}"
}

# ===== MAIN =====
mostrar_banner
pedir_url
analise_rapida
escolher_download
download_direcionado

echo ""
echo -e "${GREEN}👋 Script finalizado!${NC}"
echo ""
