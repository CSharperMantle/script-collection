<#
.SYNOPSIS
    Compress images and output JPG in progressive bit order with
    FFMPEG.

.DESCRIPTION
    This script iterates over all files in given path and feeds them
    to FFMPEG. Compressed and converted outputs are placed in
    given output folder. No format check is performed
    during this process.

.NOTES
    `ffmpeg.exe` should be in `$env:PATH` for this script to run
    normally.

    This script is licensed under an MIT license.
    Copyright (c) 2023 Rong Bao <baorong2005@126.com>

.PARAMETER Path
    Working path to find video files in.
.PARAMETER OutputPath
    Path to place output files.
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
    [Alias("OP")]
    [ValidateNotNullOrEmpty()]
    [string]
    $OutputPath
)

$files = Get-ChildItem -Path $Path -File
$files_count = $files | Measure-Object | ForEach-Object { $_.Count }
$i = 0

if (-not (Test-Path -Path $OutputPath)) {
    Write-Verbose "$OutputPath does not exist. Creating one..."
    New-Item -Path $OutputPath -ItemType Directory -WhatIf:$WhatIfPreference -Confirm:$ConfirmPreference | Out-Null
}

foreach ($f in $files) {
    $out_path = "$OutputPath\$($f.BaseName)_%d.jpg"

    if (-not ($PSCmdlet.ShouldProcess($f.FullName))) {
        Write-Output "ffmpeg.exe -i $($f.FullName) -field_order progressive $out_path -loglevel quiet"
    }
    else {
        ffmpeg.exe -i $($f.FullName) -field_order progressive $out_path -loglevel quiet
    }

    $i += 1
    Write-Progress -Activity "Running" -Status "$i in $files_count" -PercentComplete $($i / $files_count * 100)
}