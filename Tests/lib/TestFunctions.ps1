[cmdletbinding()]
param()

Write-Verbose "Loading test functions."
[hashtable]$mocks = @{ }

function Assert-Equals {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory= $true)]
        [object]$Expected,

        [Parameter(Mandatory= $true)]
        [object]$Actual)

    Write-Verbose "Asserting equals. Expected: '$Expected' ; Actual: '$Actual'."
    if ($Expected -ne $Actual) {
        throw "Assert equals failed. Expected: '$Expected' ; Actual: '$Actual'."
    }
}

function Assert-Throws {
    [cmdletbinding()]
    param(
        [ValidateNotNull()]
        [Parameter(Mandatory= $true)]
        [scriptblock]$ScriptBlock)

    Write-Verbose "Asserting script block should throw: {$ScriptBlock}"
    $didThrow = $false
    try {
        & $ScriptBlock
    } catch {
        Write-Verbose "Success. Caught exception: $($_.Exception.Message)"
        $didThrow = $true
    }

    if (!$didThrow) {
        throw "Expected script block to throw."
    }
}

function Assert-WasCalled {
    [cmdletbinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [object[]]$Arguments,

        [scriptblock]$MatchEvaluator)

    # Check if the command is already registered.
    Write-Verbose "Asserting was-called: $Command"
    if ($Arguments -ne $null) {
        $OFS = " "
        Write-Verbose "Arguments: $Arguments"
    }

    if ($MatchEvaluator) {
        Write-Verbose "MatchEvaluator: $($MatchEvaluator.ToString().Trim())"
    }

    $registration = $mocks[$Command]
    if (!$registration) {
        throw "Mock registration not found for command: $Command"
    }

    if (!$MatchEvaluator -and ($Arguments -eq $null)) {
        if (!$registration.Invocations.Length) {
            throw "Assert was-called failed. Command was not called: $Command"
        }
    } elseif ($MatchEvaluator) {
        $found = $false
        foreach ($invocation in $registration.Invocations) {
            if (& $MatchEvaluator @invocation) {
                $found = $true
            }
        }

        if (!$found) {
            foreach ($invocation in $registration.Invocations) {
                $OFS = " "
                Write-Verbose "Registered invocation: $invocation"
            }

            throw "Assert was-called failed. Command was not called according to the specified match evaluator. Command: $Command ; MatchEvaluator: $($MatchEvaluator.ToString().Trim())"
        }
    } else {
        $found = $false
        foreach ($invocation in $registration.Invocations) {
            if ($Arguments.Length -eq $invocation.Length) {
                $found = $true
                for ($i = 0 ; $i -lt $Arguments.Length ; $i++) {
                    if ($Arguments[$i] -ne $invocation[$i]) {
                        $found = $false
                    }
                }

                if ($found) {
                    break
                }
            }
        }

        if (!$found) {
            $OFS = " "
            throw "Assert was-called failed. Command was not called with the specified arguments. Command: $Command ; Arguments: $Arguments"
        }
    }
}

function Register-WhenCalled {
    [cmdletbinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [scriptblock]$Func,

        [object[]]$Arguments,

        [scriptblock]$MatchEvaluator)

    # Check if the command is already registered.
    Write-Verbose "Registering when-called for command: $Command"
    $registration = $mocks[$Command]
    if (!$registration) {
        # Create the registration object.
        Write-Verbose "Registering command."
        $registration = New-Object -TypeName psobject -Property @{
            'Command' = $Command
            'Implementations' = @( )
            'Invocations' = @( )
        }

        # Register the mock.
        $mocks[$Command] = $registration

        # Define the command.
        $null = New-Item -Path "function:\script:$Command" -Value {
            param()

            # Lookup the registration.
            $commandName = $MyInvocation.InvocationName
            Write-Verbose "Invoking mock command: $commandName"
            $registration = $mocks[$MyInvocation.InvocationName];
            if (!$registration) {
                throw "Unexpected exception. Registration not found for command: $commandName"
            }

            # Record the invocation.
            $registration.Invocations += ,$args

            # Search for a matching implementation.
            $matchingImplementation = $null
            foreach ($implementation in $registration.Implementations) {
                # Attempt to match the implementation.
                $isMatch = $false
                if (!$implementation.MatchEvaluator -and ($implementation.Arguments -eq $null)) {
                    # Match anything if no match evaluator or arguments specified.
                    $isMatch = $true
                } elseif (& $implementation.MatchEvaluator @args) {
                    # Match evaluator returned true.
                    Write-Verbose "Matching implementation found using MatchEvaluator: $($implementation.MatchEvaluator.ToString().Trim())"
                    $isMatch = $true
                } elseif ($Arguments.Length -eq $args.Length) {
                $host.EnterNestedPrompt()
                    # Check if all arguments match.
                    $isMatch = $true
                    for ($i = 0 ; $i -lt $Arguments.Length ; $i++) {
                        if ($Arguments[$i] -ne $args[$i]) {
                            $isMatch = $false
                            break
                        }
                    }

                    if ($isMatch) {
                        $OFS = " "
                        Write-Verbose "Matching implementation found using Arguments: $Arguments"
                    }
                }

                # Validate multiple matches not found.
                if ($isMatch -and $matchingImplementation) {
                    throw "Multiple matching implementations found for command: $commandName"
                }

                # Store the matching implementation.
                if ($isMatch) {
                    $matchingImplementation = $implementation
                }
            }

            # Invoke the matching implementation.
            if (($matchingImplementation -eq $null) -or ($matchingImplementation.Func -eq $null)) {
                Write-Verbose "Command is stubbed."
            } else {
                Write-Verbose "Invoking Func: $($matchingImplementation.Func.ToString().Trim())"
                & $matchingImplementation.Func @args
            }
        }
    }

    # Check if an implementation is specified.
    $implementation = $null
    if ((!$Func) -and (!$MatchEvaluator) -and (!$Arguments)) {
        Write-Verbose "Registered stub."
    } else {
        # Add the implementation to the registration object.
        Write-Verbose "Registering implementation."
        if ($Arguments -ne $null) {
            $OFS = " "
            Write-Verbose "Arguments: $Arguments"
        }

        if ($MatchEvaluator) {
            Write-Verbose "MatchEvaluator: $($MatchEvaluator.ToString().Trim())"
        }

        if ($Func) {
            Write-Verbose "Func: $($Func.ToString().Trim())"
        }

        $implementation = New-Object -TypeName psobject -Property @{
            'Arguments' = $Arguments
            'Func' = $Func
            'MatchEvaluator' = $MatchEvaluator
        }
        $registration.Implementations += $implementation
    }
}

# Stub common commands.
Register-WhenCalled -Command Import-Module
Register-WhenCalled -Command Invoke-Tool
Register-WhenCalled -Command Get-Command
