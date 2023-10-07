<#
.SYNOPSIS
    Remove files smaller than a given threshold.

.DESCRIPTION
    This script iterates over all files in target path and compares
    their sizes with provided threshold in KB (1024 bytes). It then
    removes all files whose size is smaller than the threshold.

.NOTES
    Hidden files and readonly files are not removed. This script does
    NOT move files to Recycle Bin.

    This script is licensed under an MIT license.
    Copyright (c) 2023 Rong Bao <baorong2005@126.com>

.PARAMETER Path
    Working path.
.PARAMETER SizeThresholdKB
    Threshold of file size in KB (1024 bytes).
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

    [Parameter(Mandatory = $true, Position = 1)]
    [Alias("ST")]
    [uint]
    $SizeThresholdKB
)

$files = Get-ChildItem -Path $Path -File
$files_count = $files | Measure-Object | ForEach-Object { $_.Count }
$i = 0

foreach ($f in $files) {
    $sizeKB = $f.Length / 1KB
    if ($sizeKB -ge $SizeThresholdKB) {
        Write-Verbose "$($f.FullName): $sizeKB >= $SizeThresholdKB, skipping"
        continue
    }
    
    Remove-Item -Path $($f.FullName) -WhatIf:$WhatIfPreference -Confirm:$ConfirmPreference

    $i += 1
    Write-Progress -Activity "Running" -Status "$i in $files_count" -PercentComplete $($i / $files_count * 100)
}
