# Sea Beast Puzzle Solver

Projeto para resolver o tabuleiro deslizante 4x4 do Sea Beast Puzzle.

## Arquitetura

- **Delta/Lua:** lê as 16 casas e identifica o vazio.
- **API Python:** recebe `board` e calcula a sequência fora do Roblox.
- **Delta/Lua:** recebe `moves` e executa os cliques, verificando cada troca.

O GitHub guarda o código. O cálculo acontece no serviço web implantado (por exemplo, Render), não no GitHub Actions.

## Arquivos

- `solver.py`: algoritmo IDA* em Python.
- `server.py`: API HTTP Flask.
- `requirements.txt`: dependências.
- `render.yaml`: configuração inicial de deploy no Render.

## API

`GET /` verifica se o serviço está online.

`POST /solve` recebe:

```json
{
  "board": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 0, 15],
  "time_limit": 8,
  "node_limit": 8000000
}
```

O tabuleiro é uma lista de 16 inteiros em ordem da esquerda para a direita e de cima para baixo. O espaço vazio é `0`. A resposta contém `moves`, uma lista de posições de 1 a 16 indicando qual peça clicar em cada passo.

Se a variável de ambiente `API_TOKEN` estiver configurada, envie o mesmo valor no cabeçalho `X-API-Key`.

## Deploy

1. No Render, crie um **Web Service** conectado a este repositório.
2. O arquivo `render.yaml` fornece os comandos de build e start.
3. Configure/guarde o valor de `API_TOKEN` no painel do serviço.
4. Use a URL pública do serviço no cliente Lua.

## Observações

- O serviço pode levar mais que dois segundos em tabuleiros difíceis; o tempo depende da configuração inicial e dos recursos do host.
- O plano gratuito pode suspender o serviço quando inativo, aumentando o tempo da primeira chamada.
- Nunca coloque tokens privados do GitHub dentro do script Lua.
- Antes de executar uma sequência no jogo, o cliente deve validar cada movimento e parar se o tabuleiro não confirmar a troca.
