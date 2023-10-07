<#
.SYNOPSIS
    Sort folders according to Simai/AstroDX score genre metadata.

.DESCRIPTION
    This script iterates over all folders in form of `^music.*$`
    in target path and moves them to new folders according to
    their genre metadata in `maidata.txt` in each of them.

.NOTES
    Hidden files and readonly files are not moved.

    This script is licensed under an MIT license.
    Copyright (c) 2023-present Rong Bao <baorong2005@126.com>

.PARAMETER Path
    Working path.
#>

<#
 # Copyright (c) 2023 Rong Bao <baorong2005@126.com>
 # 
 # Permission is hereby granted, free of charge, to any person obtaining a copy
 # of this software and associated documentation files (the "Software"), to deal
 # in the Software without restriction, including without limitation the rights
 # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 # copies of the Software, and to permit persons to whom the Software is
 # furnished to do so, subject to the following conditions:
 # 
 # The above copyright notice and this permission notice shall be included in all
 # copies or substantial portions of the Software.
 # 
 # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 # SOFTWARE.
 #>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true)]
    [Alias("PSPath")]
    [ValidateNotNullOrEmpty()]
    [string]
    $Path
)

$dirs = Get-ChildItem -Path $Path -Directory -Filter "music*"
$dirs_count = $dirs | Measure-Object | ForEach-Object { $_.Count }
$i = 0

foreach ($d in dirs) {
    $metadata_path = Join-Path -Path $d.FullName -ChildPath "maidata.txt"
    $genre = Select-String -Path $metadata_path -Pattern "^&genre=(.+)$" | ForEach-Object { $_.Matches.Groups[1].Value }

    if ($genre) {
        $dest = Join-Path -Path $Path -ChildPath $genre
        if (-not (Test-Path -Path $dest)) {
            New-Item -ItemType Directory -Path $dest -WhatIf:$WhatIfPreference -Confirm:$ConfirmPreference | Out-Null
        }
        Move-Item -Path $d -Destination $dest -WhatIf:$WhatIfPreference -Confirm:$ConfirmPreference
    }
    else {
        Write-Warning "No genre found in $metadata_path; ignoring"
    }

    $i += 1
    Write-Progress -Activity "Running" -Status "$i in $dirs_count" -PercentComplete $($i / $files_count * 100)
}
