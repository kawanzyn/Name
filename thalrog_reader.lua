-- THALROG 3x3 PUZZLE - LEITOR / INVESTIGADOR
-- Apenas inspeciona objetos. NAO clica, NAO move pecas e NAO inicia o puzzle.
-- Execute no Delta quando estiver perto da mesa/puzzle do Thalrog.

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local GUI_NAME = "ThalrogPuzzleReader"
local old = CoreGui:FindFirstChild(GUI_NAME)
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 430, 0, 390)
frame.Position = UDim2.new(0.5, -215, 0.5, -195)
frame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 9)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -42, 0, 30)
title.Position = UDim2.new(0, 10, 0, 4)
title.BackgroundTransparency = 1
title.Text = "THALROG 3x3 - LEITOR (SOMENTE LEITURA)"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 28, 0, 26)
close.Position = UDim2.new(1, -34, 0, 5)
close.Text = "X"
close.TextColor3 = Color3.new(1,1,1)
close.BackgroundColor3 = Color3.fromRGB(145, 50, 50)
close.Font = Enum.Font.GothamBold
close.TextSize = 12
close.Parent = frame
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 22)
status.Position = UDim2.new(0, 10, 0, 35)
status.BackgroundTransparency = 1
status.Text = "Pronto. Fique perto do puzzle e aperte ANALISAR."
status.TextColor3 = Color3.fromRGB(160, 220, 255)
status.Font = Enum.Font.Gotham
status.TextSize = 10
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local output = Instance.new("TextBox")
output.Size = UDim2.new(1, -20, 1, -112)
output.Position = UDim2.new(0, 10, 0, 60)
output.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
output.TextColor3 = Color3.fromRGB(220, 230, 240)
output.Font = Enum.Font.Code
output.TextSize = 10
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = false
output.MultiLine = true
output.ClearTextOnFocus = false
output.TextEditable = true
output.Text = "Nenhuma leitura ainda."
output.Parent = frame
Instance.new("UICorner", output).CornerRadius = UDim.new(0, 6)

local scan = Instance.new("TextButton")
scan.Size = UDim2.new(0.48, -6, 0, 32)
scan.Position = UDim2.new(0, 10, 1, -42)
scan.BackgroundColor3 = Color3.fromRGB(35, 125, 80)
scan.Text = "ANALISAR OBJETOS"
scan.TextColor3 = Color3.new(1,1,1)
scan.Font = Enum.Font.GothamBold
scan.TextSize = 11
scan.Parent = frame
Instance.new("UICorner", scan).CornerRadius = UDim.new(0, 6)

local copy = Instance.new("TextButton")
copy.Size = UDim2.new(0.48, -6, 0, 32)
copy.Position = UDim2.new(0.52, 2, 1, -42)
copy.BackgroundColor3 = Color3.fromRGB(55, 85, 145)
copy.Text = "COPIAR RELATORIO"
copy.TextColor3 = Color3.new(1,1,1)
copy.Font = Enum.Font.GothamBold
copy.TextSize = 11
copy.Parent = frame
Instance.new("UICorner", copy).CornerRadius = UDim.new(0, 6)

local lastReport = ""

local function fullPath(obj)
    local names = {}
    local current = obj
    while current and current ~= Workspace do
        table.insert(names, 1, current.Name)
        current = current.Parent
    end
    return "Workspace." .. table.concat(names, ".")
end

local function descendantsOfClass(root, className)
    local found = {}
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA(className) then table.insert(found, obj) end
    end
    return found
end

local function getImageIds(part)
    local ids = {}
    for _, obj in ipairs(part:GetDescendants()) do
        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            table.insert(ids, obj.Name .. "=" .. tostring(obj.Image))
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            table.insert(ids, obj.Name .. "=" .. tostring(obj.Texture))
        end
    end
    return ids
end

local function inspect()
    status.Text = "Varrendo Workspace..."
    scan.Active = false
    local groups = {}
    local allParts = {}
    local total = 0

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local clicks = descendantsOfClass(obj, "ClickDetector")
            local surfaces = descendantsOfClass(obj, "SurfaceGui")
            local images = getImageIds(obj)
            if #clicks > 0 or #surfaces > 0 or #images > 0 then
                total = total + 1
                table.insert(allParts, {
                    part = obj,
                    clicks = #clicks,
                    surfaces = surfaces,
                    images = images
                })
                if #clicks > 0 and #surfaces > 0 then
                    local parent = obj.Parent
                    groups[parent] = groups[parent] or {}
                    table.insert(groups[parent], obj)
                end
            end
        end
    end

    local lines = {}
    table.insert(lines, "THALROG PUZZLE READER - RELATORIO")
    table.insert(lines, "Jogador: " .. player.Name)
    table.insert(lines, "Objetos relevantes encontrados: " .. total)
    table.insert(lines, "Partes com ClickDetector + SurfaceGui agrupadas pelo mesmo pai:")
    table.insert(lines, "--------------------------------------------------")

    local candidates = {}
    for parent, parts in pairs(groups) do
        if #parts >= 4 then
            table.insert(candidates, {parent = parent, parts = parts})
        end
    end
    table.sort(candidates, function(a,b) return #a.parts > #b.parts end)

    table.insert(lines, "GRUPOS CANDIDATOS: " .. #candidates)
    for index, group in ipairs(candidates) do
        table.insert(lines, "")
        table.insert(lines, "CANDIDATO " .. index .. " | quantidade=" .. #group.parts)
        table.insert(lines, "PAI: " .. fullPath(group.parent))
        table.sort(group.parts, function(a,b)
            local na, nb = tonumber(a.Name), tonumber(b.Name)
            if na and nb then return na < nb end
            return a.Name < b.Name
        end)
        for _, part in ipairs(group.parts) do
            local surfText = {}
            for _, surface in ipairs(descendantsOfClass(part, "SurfaceGui")) do
                table.insert(surfText, surface.Name .. "(Enabled=" .. tostring(surface.Enabled) .. ")")
            end
            local imageList = getImageIds(part)
            table.insert(lines, "  PECA: " .. part.Name .. " | " .. fullPath(part))
            table.insert(lines, "    Pos: " .. tostring(part.Position))
            table.insert(lines, "    Size: " .. tostring(part.Size))
            table.insert(lines, "    ClickDetector: SIM | SurfaceGui: " .. table.concat(surfText, ", "))
            table.insert(lines, "    IMAGENS: " .. (#imageList > 0 and table.concat(imageList, " ; ") or "nenhuma"))
        end
    end

    table.insert(lines, "")
    table.insert(lines, "AMOSTRA DE OUTROS OBJETOS COM IMAGEM (max 80):")
    local shown = 0
    for _, item in ipairs(allParts) do
        if #item.images > 0 and shown < 80 then
            shown = shown + 1
            table.insert(lines, "  " .. fullPath(item.part) .. " | " .. table.concat(item.images, " ; "))
        end
    end

    if #candidates == 0 then
        table.insert(lines, "")
        table.insert(lines, "NAO ACHEI GRUPO COM 4+ pecas contendo ClickDetector e SurfaceGui.")
        table.insert(lines, "Fique mais perto da mesa, abra/inicie a tela do puzzle se necessario e analise novamente.")
        table.insert(lines, "O script nao clicou nem iniciou nada.")
    end

    lastReport = table.concat(lines, "\n")
    output.Text = lastReport
    status.Text = "Leitura concluida. Candidatos: " .. #candidates .. " | sem movimentos."
    scan.Active = true
end

scan.MouseButton1Click:Connect(function()
    task.spawn(function()
        local ok, err = pcall(inspect)
        if not ok then
            status.Text = "Erro na leitura: " .. tostring(err)
            scan.Active = true
        end
    end)
end)

copy.MouseButton1Click:Connect(function()
    local clipboard = setclipboard or toclipboard
    if clipboard then
        local ok = pcall(function() clipboard(lastReport) end)
        status.Text = ok and "Relatorio copiado!" or "Nao foi possivel copiar; selecione o texto."
    else
        output:CaptureFocus()
        output.CursorPosition = #output.Text + 1
        status.Text = "Clipboard indisponivel: selecione e copie o texto."
    end
end)

print("[THALROG READER] Carregado. Somente leitura; nao executa movimentos.")
status.Text = "Carregado. Fique perto do puzzle e aperte ANALISAR OBJETOS."
