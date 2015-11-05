function Format-ArgumentsParameter {
    [cmdletbinding()]
    param(
        [string]$GulpFile,
        [string]$Targets,
        [string]$Arguments
    )

    $arguments = "--gulpfile `"$gulpFile`" $arguments"
    if($targets) {
        $arguments = "$targets $arguments"
    }

    $arguments
}

function Get-GulpCommand {
    [cmdletbinding()]
    param()

    # try to find gulp in the path
    $gulp = Get-Command -Name gulp -ErrorAction SilentlyContinue
    if ($gulp) {
        $gulp
        return
    }

    Write-Verbose "try to find gulp in the node_modules in the sources directory"
    $buildSourcesDirectory = Get-TaskVariable -Context $distributedTaskContext -Name "Build.SourcesDirectory"
    $nodeBinPath = Join-Path -Path $buildSourcesDirectory -ChildPath 'node_modules\.bin'

    if(Test-Path -Path $nodeBinPath -PathType Container)
    {
        $gulpPath = Join-Path -Path $nodeBinPath -ChildPath "gulp.cmd"
        Write-Verbose "Looking for gulp.cmd in $gulpPath"
        $gulp = Get-Command -Name $gulpPath -ErrorAction SilentlyContinue
        if ($gulp) {
            $gulp
            return
        }
    }

    Write-Verbose "Recursively searching for gulp.cmd in $buildSourcesDirectory"
    $searchPattern = Join-Path -Path $buildSourcesDirectory -ChildPath '**\gulp.cmd'
    $foundFiles = Find-Files -SearchPattern $searchPattern
    foreach($file in $foundFiles)
    {
        $gulpPath = $file;
        Get-Command -Name $gulpPath
        return
    }

    try {
        Get-Command -Name gulp -ErrorAction Stop
    } catch {
        throw $_.Exception
    }
}

function Get-WorkingDirectoryParameter {
    [cmdletbinding()]
    param(
        [string]$Cwd
    )

    if($cwd) {
        Write-Verbose "Setting working directory to $cwd"
        Set-Location $cwd
    } else {
        $location = Get-Location
        $cwd = $location.Path
    }

    $cwd
}