Aqui está um **README.md completo**, já adaptado para o nome correto do arquivo: **`baixa-vods.sh`**.

Pronto para colocar no GitHub.

---

# 📥 Script Organizador de Filmes e Séries – `baixa-vods.sh`

O script **baixa-vods.sh** processa uma lista IPTV em formato M3U, baixa o conteúdo da URL, descarta canais e organiza **FILMES** e **SÉRIES** em uma estrutura de pastas altamente organizada.

Ideal para quem trabalha com VOD, acervos pessoais ou sistemas como **XUIONE**, **aaPanel/NGINX**, **M3U indexing**, entre outros.

---

## 🚀 Funcionalidades

✔ Baixa uma lista M3U diretamente da internet
✔ Ignora canais ao processar
✔ Separa automaticamente filmes e séries
✔ Cria categorias conforme aparecem na listam3u
✔ Detecta temporadas e episódios (SxxEyy)
✔ Cria uma estrutura limpa e padronizada
✔ Gera arquivos `.mp4` contendo o link real do vídeo

---

## 🧩 Estrutura Final Criada

```
biblioteca/
 ├── filmes/
 │     └── Categoria/
 │           └── nome_do_filme.mp4
 └── series/
       └── Categoria/
             └── Nome_da_Série/
                   ├── tp01/
                   │    ├── ep01.mp4
                   │    └── ep02.mp4
                   └── tp02/
                        └── ep01.mp4
```

---

## 📥 Instalação & Permissões

Dê permissão de execução:

```bash
chmod +x baixa-vods.sh
```

---

## ▶️ Como Executar

Use assim:

```bash
./baixa-vods.sh "https://site.com/lista.m3u"
```

> ⚠️ A URL precisa ser direta para uma lista M3U ou M3U8.
> O script irá baixar temporariamente o arquivo e iniciar o processamento.

---

## 📦 Requisitos

Você deve ter:

```bash
sudo apt install curl grep sed coreutils -y
```

---

## 📌 O Que Cada Arquivo Gerado Contém?

Os arquivos `.mp4` NÃO são o vídeo final, mas sim um arquivo contendo **o link do stream real**, para permitir download posterior ou integração com players.

---

## 🔧 Tecnologias Usadas

* **Bash**
* `curl`
* `grep`
* `sed`
* Processamento linha a linha

---

## 📅 Possíveis melhorias futuras

* Downloader real (baixar o vídeo .mp4 da URL)
* Conversão automática para HLS
* Dashboard Web
* API de consulta
* Suporte a TMDB para organizar por metadados

---

## 📄 Licença

Uso livre para automação, acervos e projetos pessoais.

---

Se você quiser, posso gerar também:

📌 *Versão em inglês*
📌 *README com estilos e badges GitHub*
📌 *README com imagens ilustrativas*
📌 *README minimalista*

Quer alguma dessas versões?
