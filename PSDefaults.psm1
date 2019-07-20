Import-Module ./Completers.ps1

function Get-DefaultsDomainArguments {
    param(
        [string] $Domain,
        [switch] $GlobalDomain,
        [string] $ApplicationName
    )
    if ($Domain) {
        $Domain
    } elseif ($GlobalDomain) {
        '-globalDomain'
    } elseif ($ApplicationName) {
        '-app'
        $ApplicationName
    }
}

function Get-DefaultsDomain {
    <#
    .SYNOPSIS
    Lists all macOS defaults domains
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType([string])]
    param(
        [Parameter(ParameterSetName = 'CurrentHost')]
        [switch] $CurrentHost,

        [Parameter(ParameterSetName = 'HostName')]
        [string] $HostName
    )

    process {
        $params = @()
        if ($HostName) {
            $params += '-host', $HostName
        }
        if ($CurrentHost) {
            $params += '-currentHost'
        }
        (defaults @params domains) -split ', '
    }
}
Export-ModuleMember -Function Get-DefaultsDomain

function Get-DefaultsValue {
    <#
    .SYNOPSIS
    Shows macOS defaults for a given domain, key
    #>
    [CmdletBinding(DefaultParameterSetName = 'Domain')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'Domain', Position = 0, ValueFromPipeline)]
        [string] $Domain,

        [Parameter(Mandatory, ParameterSetName = 'GlobalDomain')]
        [switch] $GlobalDomain,

        [Parameter(Mandatory, ParameterSetName = 'ApplicationName')]
        [string] $ApplicationName,

        [Parameter(Position = 1)]
        [string] $Key
    )

    process {
        $defaultArgs = Get-DefaultsDomainArguments -Domain $Domain -GlobalDomain:$GlobalDomain -ApplicationName $ApplicationName
        $plist = [xml](defaults export $defaultArgs -)
        [hashtable]$dict = $plist.DocumentElement.ChildNodes | ConvertFrom-DefaultsXml
        if ($Key) {
            $dict.$Key
        } else {
            $dict
        }
    }
}
Export-ModuleMember -Function Get-DefaultsValue

function ConvertFrom-DefaultsXml {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [System.Xml.XmlElement] $Element
    )

    process {
        Write-Debug "Element name: $($Element.Name)"
        switch ($Element.Name) {
            'true' { $true }
            'false' { $false }
            'string' { $Element.InnerText }
            'real' { [double]$Element.InnerText }
            'integer' { [bigint]$Element.InnerText }
            'date' {
                [DateTime]::Parse($Element.InnerText, $null, [Globalization.DateTimeStyles]::RoundtripKind)
            }
            'data' { [System.Convert]::FromBase64String($Element.InnerText.Trim()) }
            'array' {
                $Element.ChildNodes | ConvertFrom-DefaultsXml
            }
            'dict' {
                $dict = @{ }
                foreach ($child in $Element.ChildNodes) {
                    if ($child.Name -eq 'key') {
                        $key = $child.InnerText
                    } else {
                        $dict[$key] = ConvertFrom-DefaultsXml -Element $child
                    }
                }
                $dict
            }
        }
    }
}

function Remove-DefaultsDomain {
    <#
    .SYNOPSIS
    Deletes a given macOS defaults domain and all its settings
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string] $Domain
    )

    process {
        $shouldProcessCaption = "Removing defaults domain"
        $shouldProcessDescription = "Removing defaults domain $Domain"
        $shouldProcessWarning = "Do you want to remove defaults domain $Domain?"

        if ($PSCmdlet.ShouldProcess($shouldProcessDescription, $shouldProcessWarning, $shouldProcessCaption)) {
            defaults delete $Domain
        }
    }
}
Export-ModuleMember -Function Remove-DefaultsDomain

function Remove-DefaultsValue {
    <#
    .SYNOPSIS
    Deletes a given macOS defaults key in a domain
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string] $Domain,

        [Parameter(Mandatory, Position = 1)]
        [string] $Key
    )

    process {
        $shouldProcessCaption = "Removing defaults value"
        $shouldProcessDescription = "Removing defaults key $Key in domain $Domain"
        $shouldProcessWarning = "Do you want to remove defaults key $Key in domain $Domain?"

        if ($PSCmdlet.ShouldProcess($shouldProcessDescription, $shouldProcessWarning, $shouldProcessCaption)) {
            defaults delete $Domain $Key
        }
    }
}
Export-ModuleMember -Function Remove-DefaultsValue

function Set-DefaultsValue {
    <#
    .SYNOPSIS
    Sets a given macOS defaults key in a domain to a new value
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ParameterSetName = 'Domain', Position = 0, ValueFromPipeline)]
        [string] $Domain,

        [Parameter(Mandatory, ParameterSetName = 'GlobalDomain')]
        [switch] $GlobalDomain,

        [Parameter(Mandatory, ParameterSetName = 'ApplicationName')]
        [string] $ApplicationName,

        [Parameter(Mandatory, Position = 1)]
        [string] $Key,

        [Parameter(Mandatory, Position = 2)]
        $Value,

        [switch] $Add
    )

    process {
        $defaultsArgs = Get-DefaultsDomainArguments -Domain $Domain -GlobalDomain:$GlobalDomain -ApplicationName $ApplicationName

        # Check previous value
        $prevValue = try {
            Get-DefaultsValue -Domain $Domain -Key $Key
        } catch {}
        if ($null -eq $prevValue) {
            Write-Verbose "Adding key $Key to domain $Domain, did not exist"
        } else {
            Write-Verbose "Changing key $Key in domain $Domain from $prevValue to $Value"
            if ($Value -isnot $prevValue.GetType()) {
                Write-Warning "Changing type of key $Key in domain $Domain from $($prevValue.GetType().Name) to $($Value.GetType().Name)"
            }
        }

        $valueArgs = ConvertTo-DefaultsValueArguments -Value $Value -Add:$Add
        Write-Debug "Value arguments $valueArgs"

        $shouldProcessCaption = "Setting defaults value"
        $shouldProcessDescription = "Setting defaults value of $Key in domain $Domain to value $Value"
        $shouldProcessWarning = "Do you want to set defaults value of $Key in domain $Domain to value $Value?"
        if ($PSCmdlet.ShouldProcess($shouldProcessDescription, $shouldProcessWarning, $shouldProcessCaption)) {
            defaults write $defaultsArgs $Key @valueArgs
        }
    }
}
Export-ModuleMember -Function Set-DefaultsValue

function ConvertTo-DefaultsValueArguments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        $Value,

        [switch] $Add
    )
    process {
        if ($Value -is [string]) {
            '-string', $Value
        } elseif ($Value -is [int] -or $Value -is [bigint]) {
            '-int'
            $Value
        } elseif ($Value -is [float] -or $Value -is [double]) {
            '-float'
            $Value
        } elseif ($Value -is [datetime]) {
            '-date'
            $Value.ToString('o')
        } elseif ($Value -is [bool]) {
            '-bool'
            ([string]$Value).ToLower()
        } elseif ($Value.GetType().Name -eq 'Byte[]') {
            '-data'
            [BitConverter]::ToString($Value).Replace('-', '')
        } elseif ($Value -is [array]) {
            if ($Add) {
                '-array-add'
            } else {
                '-array'
            }
            $Value | ConvertTo-DefaultsValueArguments
        } elseif ($Value -is [hashtable]) {
            if ($Add) {
                '-dict-add'
            } else {
                '-dict'
            }
            $Value.GetEnumerator() | ForEach-Object {
                $_.Name
                ConvertTo-DefaultsValueArguments -Value $_.Value
            }
        }
    }
}
