-- SEA BEAST PUZZLE - CLIENT DELTA
-- Le o tabuleiro, consulta a API externa e executa os movimentos confirmados.
-- A URL sera preenchida depois do deploy do servidor.

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local API_URL = "https://COLOQUE-A-URL-DO-RENDER-AQUI/solve"
local MOVE_TIMEOUT = 4
local TARGET = {
    ["16991583334"] = 1, ["16991583165"] = 2,
    ["16991582974"] = 3, ["16991582856"] = 4,
    ["16991582713"] = 5, ["16991582586"] = 6,
    ["16991582233"] = 7, ["16991582022"] = 8,
    ["16991581798"] = 9, ["16991581537"] = 10,
    ["16991581157"] = 11, ["16991580817"] = 12,
    ["16991580585"] = 13, ["16991580411"] = 14,
    ["16991580091"] = 15
}

local folder = workspace:WaitForChild("Island"):WaitForChild("SBPuzzleFolder")
local old = CoreGui:FindFirstChild("SB_ExternalSolver")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "SB_ExternalSolver"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 290, 0, 190)
frame.Position = UDim2.new(0.5, -145, 0.5, -95)
frame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "SEA BEAST - SOLVER EXTERNO"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = frame

local tokenBox = Instance.new("TextBox")
tokenBox.Position = UDim2.new(0, 10, 0, 36)
tokenBox.Size = UDim2.new(1, -20, 0, 30)
tokenBox.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
tokenBox.TextColor3 = Color3.new(1, 1, 1)
tokenBox.PlaceholderText = "Token da API (se o servidor exigir)"
tokenBox.Text = ""
tokenBox.ClearTextOnFocus = false
tokenBox.Font = Enum.Font.Gotham
tokenBox.TextSize = 11
tokenBox.Parent = frame
Instance.new("UICorner", tokenBox).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel")
status.Position = UDim2.new(0, 10, 0, 72)
status.Size = UDim2.new(1, -20, 0, 40)
status.BackgroundTransparency = 1
status.Text = "Aguardando..."
status.TextColor3 = Color3.fromRGB(180, 220, 255)
status.TextWrapped = true
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.Parent = frame

local start = Instance.new("TextButton")
start.Position = UDim2.new(0, 10, 0, 119)
start.Size = UDim2.new(1, -20, 0, 29)
start.BackgroundColor3 = Color3.fromRGB(30, 130, 75)
start.Text = "LER E RESOLVER"
start.TextColor3 = Color3.new(1, 1, 1)
start.Font = Enum.Font.GothamBold
start.TextSize = 12
start.Parent = frame
Instance.new("UICorner", start).CornerRadius = UDim.new(0, 6)

local stop = Instance.new("TextButton")
stop.Position = UDim2.new(0, 10, 0, 154)
stop.Size = UDim2.new(1, -20, 0, 25)
stop.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
stop.Text = "PARAR"
stop.TextColor3 = Color3.new(1, 1, 1)
stop.Font = Enum.Font.GothamBold
stop.TextSize = 11
stop.Parent = frame
Instance.new("UICorner", stop).CornerRadius = UDim.new(0, 6)

local running, stopRequested = false, false
local function say(msg)
    status.Text = msg
    print("[SB EXTERNAL] " .. msg)
end

local function getSurface(part)
    for _, obj in ipairs(part:GetDescendants()) do
        if obj:IsA("SurfaceGui") then return obj end
    end
end

local function getImage(part)
    for _, obj in ipairs(part:GetDescendants()) do
        if obj:IsA("ImageLabel") and obj.Name == "PuzzlePic" then
            return obj.Image
        end
    end
end

local function readBoard()
    local board, blankCount, seen = {}, 0, {}
    for i = 1, 16 do
        local part = folder:FindFirstChild(tostring(i))
        if not part then return nil, "Peca " .. i .. " ausente" end
        local surface = getSurface(part)
        if not surface then return nil, "SurfaceGui ausente: " .. i end
        if not surface.Enabled then
            board[i] = 0
            blankCount = blankCount + 1
        else
            local image = getImage(part)
            local id = image and image:match("%d+")
            local tile = id and TARGET[id]
            if not tile then return nil, "Imagem desconhecida na peca " .. i end
            if seen[tile] then return nil, "Peca duplicada: " .. tile end
            seen[tile] = true
            board[i] = tile
        end
    end
    if blankCount ~= 1 then return nil, "Espacos vazios encontrados: " .. blankCount end
    for i = 1, 15 do
        if not seen[i] then return nil, "Peca faltando: " .. i end
    end
    return board
end

local function neighbors(pos)
    local result = {}
    local row, col = math.ceil(pos / 4), (pos - 1) % 4 + 1
    if row > 1 then table.insert(result, pos - 4) end
    if row < 4 then table.insert(result, pos + 4) end
    if col > 1 then table.insert(result, pos - 1) end
    if col < 4 then table.insert(result, pos + 1) end
    return result
end

local function sameSwap(before, after, blank, nextPos, tile)
    if after[blank] ~= tile or after[nextPos] ~= 0 then return false end
    for i = 1, 16 do
        if i ~= blank and i ~= nextPos and before[i] ~= after[i] then
            return false
        end
    end
    return true
end

local function httpFunction()
    return request or http_request or (syn and syn.request)
end

local function askSolver(board)
    local req = httpFunction()
    if not req then
        return nil, "Seu Delta nao expos request/http_request"
    end
    if API_URL:find("COLOQUE%-A%-URL") then
        return nil, "Falta configurar a URL do servidor no script"
    end

    local headers = {["Content-Type"] = "application/json"}
    if tokenBox.Text ~= "" then headers["X-API-Key"] = tokenBox.Text end

    local response
    local ok, err = pcall(function()
        response = req({
            Url = API_URL,
            Method = "POST",
            Headers = headers,
            Body = HttpService:JSONEncode({board = board, time_limit = 8, node_limit = 8000000})
        })
    end)
    if not ok then return nil, "Falha HTTP: " .. tostring(err) end
    if not response then return nil, "Servidor nao respondeu" end

    local code = response.StatusCode or response.Status or 0
    local body = response.Body or response.body or ""
    local decodedOk, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    if not decodedOk then
        return nil, "Resposta invalida do servidor (HTTP " .. tostring(code) .. ")"
    end
    if not data.ok then
        return nil, data.error or ("Servidor retornou HTTP " .. tostring(code))
    end
    return data
end

local function executeMoves(moves, board)
    if not fireclickdetector then
        return false, "fireclickdetector indisponivel"
    end
    local blank
    for i = 1, 16 do if board[i] == 0 then blank = i break end end

    for step, nextPos in ipairs(moves) do
        if stopRequested then return false, "Parado pelo usuario" end
        local adjacent = false
        for _, p in ipairs(neighbors(blank)) do
            if p == nextPos then adjacent = true break end
        end
        if not adjacent or type(nextPos) ~= "number" or nextPos < 1 or nextPos > 16 then
            return false, "Sequencia invalida no movimento " .. step
        end

        local part = folder:FindFirstChild(tostring(nextPos))
        local detector = part and part:FindFirstChildWhichIsA("ClickDetector", true)
        if not detector then return false, "ClickDetector ausente na peca " .. nextPos end

        local before = table.clone(board)
        local tile = board[nextPos]
        say("Movimento " .. step .. "/" .. #moves)
        local ok, err = pcall(function() fireclickdetector(detector) end)
        if not ok then return false, "Erro no clique: " .. tostring(err) end

        local confirmed, newBoard = false, nil
        local started = os.clock()
        while os.clock() - started < MOVE_TIMEOUT do
            if stopRequested then return false, "Parado pelo usuario" end
            task.wait(0.1)
            local current = readBoard()
            if current and sameSwap(before, current, blank, nextPos, tile) then
                confirmed, newBoard = true, current
                break
            end
        end
        if not confirmed then
            return false, "Jogo nao confirmou o movimento " .. step
        end
        board = newBoard
        blank = nextPos
        task.wait(0.08)
    end
    return true
end

start.MouseButton1Click:Connect(function()
    if running then return end
    running, stopRequested = true, false
    start.Text = "PROCESSANDO..."
    task.spawn(function()
        say("Lendo tabuleiro...")
        local board, err = readBoard()
        if not board then say("Erro: " .. err)
        else
            say("Enviando tabuleiro ao servidor...")
            local data, apiError = askSolver(board)
            if not data then
                say("Solver: " .. tostring(apiError))
            else
                say("Solucao recebida: " .. data.move_count .. " movimentos")
                task.wait(0.5)
                local ok, moveError = executeMoves(data.moves, board)
                if ok then
                    local finalBoard = readBoard()
                    if finalBoard then
                        local solved = true
                        for i = 1, 15 do if finalBoard[i] ~= i then solved = false break end end
                        if finalBoard[16] ~= 0 then solved = false end
                        say(solved and "QUEBRA-CABECA RESOLVIDO!" or "Sequencia terminou; confira o tabuleiro")
                    else
                        say("Sequencia terminou; releitura falhou")
                    end
                else
                    say("Execucao interrompida: " .. tostring(moveError))
                end
            end
        end
        running = false
        start.Text = "LER E RESOLVER"
    end)
end)

stop.MouseButton1Click:Connect(function()
    stopRequested = true
    say("Solicitando parada...")
end)

say("Cliente carregado. Configure o servidor antes de usar.")
