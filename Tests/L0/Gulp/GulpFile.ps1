[cmdletbinding()]
param()

# Arrange.
. $PSScriptRoot\..\..\lib\TestFunctions.ps1
Register-WhenCalled -Command 'Get-GulpCommand' -Arguments @( ) -Func { @{ Path = 'Some path to gulp' } }
Register-WhenCalled -Command 'Format-ArgumentsParameter' -Arguments @(
        '-GulpFile'
        'Some gulp file'
        '-Targets'
        'Some targets'
        '-Arguments'
        'Some arguments'
    ) -Func {
        'Some formatted arguments'
    }
Register-WhenCalled -Command 'Get-WorkingDirectory' -Arguments @(
        'Some working directory'
    ) -Func {
        'Some other working directory'
    }

# Act.
& $PSScriptRoot\..\..\..\Tasks\Gulp\Gulptask.ps1 -GulpFile 'Some gulp file' -Targets 'Some targets' -Arguments 'Some arguments' -Cwd 'Some working directory' -OmitDotSource

# Assert.
Assert-WasCalled -Command 'Invoke-Tool' -Arguments @(
        '-Path'
        'Some path to gulp'
        '-Arguments'
        'Some formatted arguments'
        '-WorkingFolder'
        'Some other working directory'
    )