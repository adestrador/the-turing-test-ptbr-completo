param(
    [ValidateSet('instalar','restaurar')][string]$Acao = 'instalar',
    [string]$PastaJogo = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Hash-Arquivo([string]$Caminho) {
    return (Get-FileHash -LiteralPath $Caminho -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Hash-Bytes([byte[]]$Dados) {
    $hash = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($hash.ComputeHash($Dados))).Replace('-','').ToLowerInvariant()
    } finally {
        $hash.Dispose()
    }
}

function Caminho-Seguro([string]$Base, [string]$Relativo) {
    $raiz = [IO.Path]::GetFullPath($Base).TrimEnd('\') + '\'
    $destino = [IO.Path]::GetFullPath((Join-Path $Base ($Relativo.Replace('/','\'))))
    if (-not $destino.StartsWith($raiz,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Caminho invalido no pacote.'
    }
    return $destino
}

function Testar-PastaJogo([string]$Caminho) {
    if ([string]::IsNullOrWhiteSpace($Caminho)) { return $false }
    return (Test-Path -LiteralPath (Join-Path $Caminho 'TheTuringTest\Binaries\Win64\TheTuringTest.exe') -PathType Leaf)
}

function Detectar-PastaJogo {
    $candidatos = New-Object System.Collections.Generic.List[string]
    $candidatos.Add('C:\The Turing Test')
    if (${env:ProgramFiles(x86)}) {
        $candidatos.Add((Join-Path ${env:ProgramFiles(x86)} 'Steam\steamapps\common\The Turing Test'))
    }
    if ($env:ProgramFiles) {
        $candidatos.Add((Join-Path $env:ProgramFiles 'Steam\steamapps\common\The Turing Test'))
    }
    try {
        $steam = (Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath
        if ($steam) {
            $candidatos.Add((Join-Path $steam 'steamapps\common\The Turing Test'))
            $bibliotecas = Join-Path $steam 'steamapps\libraryfolders.vdf'
            if (Test-Path -LiteralPath $bibliotecas -PathType Leaf) {
                $texto = Get-Content -LiteralPath $bibliotecas -Raw
                foreach ($resultado in [regex]::Matches($texto, '"path"\s+"([^"]+)"')) {
                    $raiz = $resultado.Groups[1].Value.Replace('\\','\')
                    $candidatos.Add((Join-Path $raiz 'steamapps\common\The Turing Test'))
                }
            }
        }
    } catch { }
    foreach ($drive in Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue) {
        $candidatos.Add((Join-Path $drive.Root 'SteamLibrary\steamapps\common\The Turing Test'))
        $candidatos.Add((Join-Path $drive.Root 'Steam\steamapps\common\The Turing Test'))
    }
    foreach ($candidato in $candidatos) {
        if (Testar-PastaJogo $candidato) { return [IO.Path]::GetFullPath($candidato) }
    }
    return 'C:\The Turing Test'
}

function Aplicar-Patch([byte[]]$Original, [string]$CaminhoPatch, [string]$HashPatch) {
    if ((Hash-Arquivo $CaminhoPatch) -ne $HashPatch) { throw 'Arquivo de patch alterado ou corrompido.' }
    $patch = [IO.File]::ReadAllBytes($CaminhoPatch)
    if (($patch.Length -lt 12) -or ([Text.Encoding]::ASCII.GetString($patch,0,8) -ne 'TTPATCH1')) {
        throw 'Formato de patch invalido.'
    }
    $quantidade = [BitConverter]::ToUInt32($patch,8)
    $cursor = 12
    $operacoes = @()
    for ($indice=0; $indice -lt $quantidade; $indice++) {
        if ($cursor + 16 -gt $patch.Length) { throw 'Patch truncado.' }
        $posicao64 = [BitConverter]::ToUInt64($patch,$cursor)
        $remover = [BitConverter]::ToUInt32($patch,$cursor+8)
        $inserir = [BitConverter]::ToUInt32($patch,$cursor+12)
        $cursor += 16
        if (($posicao64 -gt [int]::MaxValue) -or ($inserir -gt [int]::MaxValue) -or ($cursor + $inserir -gt $patch.Length)) {
            throw 'Operacao invalida no patch.'
        }
        $bytes = New-Object byte[] ([int]$inserir)
        if ($inserir -gt 0) { [Array]::Copy($patch,$cursor,$bytes,0,[int]$inserir) }
        $cursor += [int]$inserir
        $operacoes += [PSCustomObject]@{posicao=[int]$posicao64;remover=[int]$remover;bytes=$bytes}
    }
    if ($cursor -ne $patch.Length) { throw 'Dados extras no patch.' }

    $dados = $Original
    $posicaoAnterior = [int]::MaxValue
    foreach ($operacao in $operacoes) {
        $posicao = $operacao.posicao
        $remover = $operacao.remover
        $inserir = $operacao.bytes
        if (($posicao -gt $posicaoAnterior) -or ($posicao -lt 0) -or ($remover -lt 0) -or ($posicao + $remover -gt $dados.Length)) {
            throw 'Faixa invalida no patch.'
        }
        $novoTamanho = $dados.Length - $remover + $inserir.Length
        $novo = New-Object byte[] $novoTamanho
        if ($posicao -gt 0) { [Array]::Copy($dados,0,$novo,0,$posicao) }
        if ($inserir.Length -gt 0) { [Array]::Copy($inserir,0,$novo,$posicao,$inserir.Length) }
        $origemCauda = $posicao + $remover
        $tamanhoCauda = $dados.Length - $origemCauda
        if ($tamanhoCauda -gt 0) {
            [Array]::Copy($dados,$origemCauda,$novo,$posicao+$inserir.Length,$tamanhoCauda)
        }
        $dados = $novo
        $posicaoAnterior = $posicao
    }
    return ,$dados
}

function Preparar-Dados([object]$Item, [string]$Destino) {
    if ($Item.kind -eq 'patch') {
        $patch = Caminho-Seguro $PSScriptRoot $Item.patch
        return ,(Aplicar-Patch ([IO.File]::ReadAllBytes($Destino)) $patch $Item.patchHash)
    }
    if ($Item.kind -eq 'replace_any') {
        $origem = Caminho-Seguro $PSScriptRoot $Item.payload
        return ,([IO.File]::ReadAllBytes($origem))
    }
    throw 'Tipo de correcao desconhecido.'
}

$logIniciado = $false
try {
    $manifesto = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifesto.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace($PastaJogo)) {
        $sugerida = Detectar-PastaJogo
        Write-Host 'THE TURING TEST - PT-BR COMPLETO' -ForegroundColor Cyan
        Write-Host 'Dialogos e legendas em portugues, menus traduzidos e legendas maiores.'
        Write-Host ''
        Write-Host "Pasta detectada/sugerida: $sugerida"
        $entrada = Read-Host 'Pressione ENTER para confirmar ou digite outra pasta'
        if ([string]::IsNullOrWhiteSpace($entrada)) { $PastaJogo = $sugerida }
        else { $PastaJogo = $entrada.Trim().Trim('"') }
    }
    $PastaJogo = [IO.Path]::GetFullPath($PastaJogo)
    if (-not (Testar-PastaJogo $PastaJogo)) {
        throw 'Jogo nao encontrado. Selecione a pasta principal que contem a subpasta TheTuringTest.'
    }
    if (Get-Process -Name 'TheTuringTest' -ErrorAction SilentlyContinue) {
        throw 'Feche o jogo antes de continuar.'
    }

    $backup = Join-Path $PastaJogo 'Backup_PTBR_Completo_v1'
    $registro = Join-Path $backup 'backup.json'
    $log = Join-Path $PSScriptRoot ('resultado_' + $Acao + '.txt')
    try { Start-Transcript -LiteralPath $log -Force | Out-Null; $logIniciado = $true } catch { }

    if ($Acao -eq 'restaurar') {
        if (-not (Test-Path -LiteralPath $backup -PathType Container)) {
            throw 'Backup desta traducao nao encontrado.'
        }
        $itens = @()
        foreach ($modelo in $manifesto.files) {
            $origem = Caminho-Seguro $backup $modelo.path
            $destino = Caminho-Seguro $PastaJogo $modelo.path
            if (-not (Test-Path -LiteralPath $origem -PathType Leaf)) {
                throw "Falta arquivo no backup: $($modelo.path)"
            }
            $hashBackup = Hash-Arquivo $origem
            if (($modelo.kind -ne 'replace_any') -and ($modelo.originalHashes -notcontains $hashBackup) -and ($hashBackup -ne $modelo.patchedHash)) {
                throw "Backup alterado: $($modelo.path)"
            }
            if (Test-Path -LiteralPath $destino -PathType Leaf) {
                $atual = Hash-Arquivo $destino
                $permitido = ($atual -eq $modelo.patchedHash) -or ($atual -eq $hashBackup)
                if ($modelo.kind -ne 'replace_any') { $permitido = $permitido -or ($modelo.originalHashes -contains $atual) }
                if (-not $permitido) {
                    throw "Arquivo mudou depois da instalacao: $($modelo.path). Preserve suas alteracoes e restaure manualmente."
                }
            }
            $itens += [PSCustomObject]@{path=$modelo.path;hash=$hashBackup}
        }
        ConvertTo-Json -InputObject @($itens) -Depth 5 | Set-Content -LiteralPath $registro -Encoding UTF8
        foreach ($item in $itens) {
            $origem = Caminho-Seguro $backup $item.path
            $destino = Caminho-Seguro $PastaJogo $item.path
            Copy-Item -LiteralPath $origem -Destination $destino -Force
            if ((Hash-Arquivo $destino) -ne $item.hash) { throw "Falha ao restaurar: $($item.path)" }
        }
        Write-Host 'Restauracao concluida. Os arquivos anteriores foram recuperados.' -ForegroundColor Green
        Write-Host "Backup preservado em: $backup"
    } else {
        Write-Host 'Conferindo a versao do jogo e preparando a traducao...'
        $trabalhos = @()
        $alterados = 0
        $aInstalar = 0
        foreach ($item in $manifesto.files) {
            $destino = Caminho-Seguro $PastaJogo $item.path
            if (-not (Test-Path -LiteralPath $destino -PathType Leaf)) {
                throw "Arquivo nao encontrado: $($item.path)"
            }
            $atual = Hash-Arquivo $destino
            if (($item.kind -ne 'replace_any') -and ($item.originalHashes -notcontains $atual) -and ($atual -ne $item.patchedHash)) {
                throw "Versao incompativel ou arquivo modificado: $($item.path). Nenhuma alteracao foi aplicada."
            }
            if ($atual -ne $item.patchedHash) { $aInstalar++ }
            if (($item.kind -ne 'replace_any') -and ($atual -eq $item.patchedHash) -and ($item.originalHashes -notcontains $atual)) {
                $alterados++
            }
            $trabalhos += [PSCustomObject]@{item=$item;destino=$destino;hash=$atual;dados=$null}
        }

        if ($aInstalar -eq 0) {
            Write-Host 'A traducao completa ja esta instalada.' -ForegroundColor Green
        } else {
            if (($alterados -gt 0) -and ($alterados -lt @($manifesto.files | Where-Object { $_.kind -ne 'replace_any' }).Count)) {
                throw 'Instalacao parcial detectada. Execute RESTAURAR.bat antes de instalar novamente.'
            }
            foreach ($trabalho in $trabalhos) {
                if ($trabalho.hash -eq $trabalho.item.patchedHash) { continue }
                $dados = Preparar-Dados $trabalho.item $trabalho.destino
                if ((Hash-Bytes $dados) -ne $trabalho.item.patchedHash) {
                    throw "Falha ao validar a correcao: $($trabalho.item.path)"
                }
                $trabalho.dados = $dados
            }

            if (-not (Test-Path -LiteralPath $backup -PathType Container)) {
                New-Item -ItemType Directory -Path $backup | Out-Null
            }
            $registros = @()
            foreach ($trabalho in $trabalhos) {
                $copia = Caminho-Seguro $backup $trabalho.item.path
                if (Test-Path -LiteralPath $copia -PathType Leaf) {
                    $hashCopia = Hash-Arquivo $copia
                    if (($trabalho.item.kind -ne 'replace_any') -and ($trabalho.item.originalHashes -notcontains $hashCopia) -and ($hashCopia -ne $trabalho.item.patchedHash)) {
                        throw "Backup anterior alterado: $($trabalho.item.path)"
                    }
                } else {
                    New-Item -ItemType Directory -Path (Split-Path -Parent $copia) -Force | Out-Null
                    Copy-Item -LiteralPath $trabalho.destino -Destination $copia
                    $hashCopia = Hash-Arquivo $copia
                    if ($hashCopia -ne $trabalho.hash) { throw 'Falha ao conferir o backup.' }
                }
                $registros += [PSCustomObject]@{path=$trabalho.item.path;hash=$hashCopia}
            }
            ConvertTo-Json -InputObject @($registros) -Depth 5 | Set-Content -LiteralPath $registro -Encoding UTF8

            try {
                foreach ($trabalho in $trabalhos) {
                    if ($trabalho.hash -eq $trabalho.item.patchedHash) { continue }
                    if ((Hash-Arquivo $trabalho.destino) -ne $trabalho.hash) { throw 'Um arquivo mudou durante a instalacao.' }
                    $temporario = $trabalho.destino + '.ptbr-completo-v1.tmp'
                    if (Test-Path -LiteralPath $temporario) { throw "Arquivo temporario ja existe: $temporario" }
                    try {
                        [IO.File]::WriteAllBytes($temporario,$trabalho.dados)
                        [IO.File]::Copy($temporario,$trabalho.destino,$true)
                    } finally {
                        if (Test-Path -LiteralPath $temporario) { Remove-Item -LiteralPath $temporario -Force }
                    }
                    if ((Hash-Arquivo $trabalho.destino) -ne $trabalho.item.patchedHash) {
                        throw "Falha ao verificar: $($trabalho.item.path)"
                    }
                }
            } catch {
                $erroOriginal = $_.Exception.Message
                $falhas = @()
                foreach ($trabalho in $trabalhos) {
                    try {
                        Copy-Item -LiteralPath (Caminho-Seguro $backup $trabalho.item.path) -Destination $trabalho.destino -Force
                    } catch {
                        $falhas += $trabalho.item.path
                    }
                }
                if ($falhas.Count -gt 0) {
                    throw "$erroOriginal. Restaure manualmente pelo backup: $($falhas -join ', ')"
                }
                throw "$erroOriginal. Os arquivos anteriores foram restaurados."
            }
            Write-Host 'Instalacao concluida: traducao PT-BR, menus traduzidos e legendas 50% maiores.' -ForegroundColor Green
            Write-Host "Backup: $backup"
            Write-Host 'Configuracao testada em 1920x1080.'
        }
    }

    if ($logIniciado) { Stop-Transcript | Out-Null; $logIniciado = $false }
    exit 0
} catch {
    Write-Host ('ERRO: ' + $_.Exception.Message) -ForegroundColor Red
    if ($logIniciado) { Stop-Transcript | Out-Null }
    exit 1
}
