[cmdletbinding()]
param()

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

function Register-WhenCalled {
    [cmdletbinding()]
    param(
        [ValidateNotNull()]
        [ValidateNotEmtpy()]
        [string]$Function,

        [scriptblock]$Do,

        [scriptblock]$MatchEvaluator)

    # Check if the function is already registered.
    $registration = $mocks[$Function]
    if (!$registration) {
        # Create the registration object.
        $registration = New-Object -TypeName psobject -Property @{
            'Function' = $Function
            'Implementations' = @( )
            'Invocations' = @( )
        }

        # Register the mock.
        $mocks[$Function] = $registration

        # Define the function.
        function script:$Function {
            [cmdletbinding()]
            param(
                [Parameter(ValueFromRemainingArguments = $true)]
                $RemainingArgs
            )

            # Lookup the registration.
            $functionName = $MyInvocation.InvocationName
            Write-Verbose "Getting mock registration for function: $functionName"
            $registration = $mocks[$MyInvocation.InvocationName];
            if (!$registration) {
                throw "Unexpected exception. Registration not found for function: $functionName"
            }

            # Record the invocation.
            $registration.Invocations += ,$RemainingArgs

            # Return if the function is just a stub.
            if (!$registration.Implementations) {
                return
            }

            # Search for a matching implementation.
            $matchingImplementation = $null
            foreach ($implementation in $registration.Implementations) {
                $isMatch = $false
                if (!$implementation.MatchEvaluator) {
                    $isMatch = $true
                } elseif (& $implementation.MatchEvaluator $RemainingArgs) {
                    $isMatch = $true
                }

                if ($isMatch -and $matchingImplementation) {
                    throw "Multiple matching implementations found for function: $functionName"
                }

                $matchingImplementation = $implementation
            }

            # Invoke the matching implementation.
            if ($matchingImplementation) {
                & $matchingImplementation $RemainingArgs
            }
        }
    }

    # Check if an implementation is specified.
    $implementation = $null
    if ($Do -or $MatchEvaluator) {
        # Add the implementation to the registration object.
        $implementation = New-Object -TypeName psobject -Property @{
            'Do' = $Do
            'MatchEvaluator' = $MatchEvaluator
        }
        $registration.Implementations += $implementation
    }
}