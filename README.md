# Sea Beast Puzzle Solver

Projeto para resolver o tabuleiro deslizante 4x4 do Sea Beast Puzzle sem fazer a busca pesada dentro do Delta.

## Arquitetura

- **Delta/Lua:** lê as 16 casas e identifica o espaço vazio.
- **API Python:** recebe `board` e calcula a sequência fora do Roblox.
- **Delta/Lua:** recebe `moves` e executa os cliques, verificando cada troca.

O GitHub guarda o código e executa os testes automatizados. O cálculo em tempo real acontece no serviço web implantado (por exemplo, Render), não no GitHub Actions.

## Arquivos

- `solver.py`: algoritmo IDA* em Python.
- `server.py`: API HTTP Flask.
- `delta_client.lua`: cliente para o Delta (leitura, requisição e movimentação verificada).
- `requirements.txt`: dependências.
- `render.yaml`: configuração inicial de deploy no Render.
- `tests/test_solver.py`: testes básicos do algoritmo.
- `.github/workflows/tests.yml`: executa os testes a cada push e pull request.

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

Se a variável de ambiente `API_TOKEN` estiver configurada, envie o mesmo valor no cabeçalho `X-API-Key`. O cliente Lua possui um campo para inserir esse token sem gravá-lo no repositório.

## Deploy

1. No Render, crie um **Web Service** conectado a este repositório.
2. O arquivo `render.yaml` fornece os comandos de build e start.
3. Copie a URL pública do serviço.
4. Abra `delta_client.lua` e substitua `https://COLOQUE-A-URL-DO-RENDER-AQUI/solve` pela URL real terminada em `/solve`.
5. Se o Render tiver criado `API_TOKEN`, copie o valor no campo de token da interface do Delta.

## Usar o cliente no Delta

Depois de configurar a URL no arquivo, carregue o arquivo Lua pelo raw URL do GitHub. O cliente lê o tabuleiro, consulta a API e só continua quando cada troca for confirmada pelo jogo.

## Limites importantes

- Ainda não há medição real de desempenho com os tabuleiros do jogo. O tempo depende da dificuldade do embaralhamento e dos recursos do host.
- O plano gratuito pode suspender o serviço quando inativo, aumentando o tempo da primeira chamada.
- O algoritmo tem limite de tempo e de nós; tabuleiros muito difíceis podem retornar limite atingido.
- Nunca coloque tokens privados do GitHub dentro do script Lua.
- O cliente para se o jogo não confirmar um movimento; não tenta clicar repetidamente no mesmo lugar.
