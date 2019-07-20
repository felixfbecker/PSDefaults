$domainCompleter = {
    [CmdletBinding()]
    param([string]$command, [string]$parameter, [string]$wordToComplete, [CommandAst]$commandAst, [Hashtable]$params)

    Get-DefaultsDomain | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [CompletionResult]::new($_, $_, [CompletionResultType]::ParameterValue, $_)
    }
}
Register-ArgumentCompleter -CommandName Get-DefaultsValue -ParameterName Domain -ScriptBlock $domainCompleter
Register-ArgumentCompleter -CommandName Set-DefaultsValue -ParameterName Domain -ScriptBlock $domainCompleter
Register-ArgumentCompleter -CommandName Remove-DefaultsValue -ParameterName Domain -ScriptBlock $domainCompleter
Register-ArgumentCompleter -CommandName Remove-DefaultsDomain -ParameterName Domain -ScriptBlock $domainCompleter

$keyCompleter = {
    [CmdletBinding()]
    param([string]$command, [string]$parameter, [string]$wordToComplete, [CommandAst]$commandAst, [Hashtable]$params)
    if (-not $params.ContainsKey('Domain')) {
        return
    }
    (Get-DefaultsValue $params.Domain).Keys |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [CompletionResult]::new($_, $_, [CompletionResultType]::ParameterValue, $_)
        }
}
Register-ArgumentCompleter -CommandName Get-DefaultsValue -ParameterName Key -ScriptBlock $keyCompleter
Register-ArgumentCompleter -CommandName Set-DefaultsValue -ParameterName Key -ScriptBlock $keyCompleter
Register-ArgumentCompleter -CommandName Remove-DefaultsValue -ParameterName Key -ScriptBlock $keyCompleter
