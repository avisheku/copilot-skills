# Copilot Skills — wire format (compact JSON default; TOON stub)

function Get-WireConfig {
    param([string]$Root = (Get-CopilotSkillsRoot))
    Get-PackConfig -Name 'wire.json' -Root $Root
}

function ConvertTo-WireEnvelope {
    param([object]$Payload, [string]$Root = (Get-CopilotSkillsRoot))
    $cfg = Get-WireConfig -Root $Root
    $envelope = [ordered]@{
        format = $cfg.format
        ts     = (Get-Date).ToUniversalTime().ToString('o')
        body   = $Payload
    }
    if ($cfg.toonEnabled) {
        throw 'TOON not enabled. Set wire.json toonEnabled only after measured pain and implementation.'
    }
    return ($envelope | ConvertTo-Json -Compress -Depth 10)
}

function ConvertFrom-WireEnvelope {
    param([string]$Json)
    $obj = $Json | ConvertFrom-Json
    return $obj.body
}

Export-ModuleMember -Function Get-WireConfig, ConvertTo-WireEnvelope, ConvertFrom-WireEnvelope
