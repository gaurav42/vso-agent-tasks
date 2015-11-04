[cmdletbinding()]
param()

# Arrange.
. $PSScriptRoot\..\..\lib\TestFunctions.ps1
Register-WhenCalled -Command 'Get-Command' -MatchEvaluator {
        $args -contains 'gulp'
    } -Func {
        New-Object -TypeName psobject -Property @{ Path = 'path to gulp' }
    }

# Act.
& $PSScriptRoot\..\..\..\Tasks\Gulp\Gulptask.ps1

# Assert.
Assert-WasCalled -Command Invoke-Tool -MatchEvaluator { write-verbose "Evaluating args: $args" ; $args[0] -eq '-path' -and $args[1] -eq 'path to gulp' }