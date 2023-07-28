<#
.SYNOPSIS
    Flatten directory structure, and copy every file in a directory tree
    to destination path.

.DESCRIPTION
    This script iterates over all files in give directory tree, and copies
    them to destination folder. Files with the same names will be appended
    a postfix of their most-inner parent folder name and number of encounterment.

.NOTES
    This script ignores hidden files, and will create output directory in
    case that it does not exist.

    This script is licensed under an MIT license.
    Copyright (c) 2023-present Rong Bao <baorong2005@126.com>

.PARAMETER Path
    Working path.
.PARAMETER To
    Path to place output files.
.PARAMETER WhatIf
    Show operations without actually running.
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
    $Path,

    [Parameter(Mandatory = $true,
        Position = 1)]
    [Alias("T")]
    [ValidateNotNullOrEmpty()]
    [string]
    $To
)

if (-not (Test-Path -Path $To -PathType Container)) {
    New-Item -Path $To -ItemType Directory -WhatIf:$WhatIfPreference -Confirm:$ConfirmPreference | Out-Null
}

$files = Get-ChildItem -Path $Path -Recurse -File
$files_count = $files | Measure-Object | ForEach-Object { $_.Count }
$i = 0

$files_list = @{}

foreach ($f in $files) {
    $final_filename = $f.Name

    if (-not $files_list.ContainsKey($final_filename)) {
        $files_list[$f.Name] = 0
    }
    elseif (Test-Path -Path "$To\$final_filename" -PathType Leaf) {
        $files_list[$f.Name] += 1
    }
    if ($files_list[$f.Name] -gt 0) {
        $final_filename = "$($f.BaseName)_$($f.Directory.BaseName)_$($files_list[$f.Name])$($f.Extension)"
    }
    $files_list[$f.Name] += 1

    $out_path = "$To\$final_filename"
    Copy-Item -Path $f.FullName -Destination $out_path -WhatIf:$WhatIfPreference -Confirm:$ConfirmPreference
    
    $i += 1
    Write-Progress -Activity "Running" -Status "$i in $files_count" -PercentComplete $($i / $files_count * 100)
}
