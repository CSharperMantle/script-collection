<#
.SYNOPSIS
    Purge PTC Creo versioned files, retaining only the latest version of each file.

.DESCRIPTION
    This scripts considers files having the form of `filename.ext.[0-9]+` as PTC Creo versioned
    files. It will delete all but the latest version of each file, then rename the remaining file
    to `filename.ext`.

.NOTES
    This script ignores hidden files.

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

$files = Get-ChildItem -Path $Path -Recurse -File

$file_max_version = @{}

foreach ($f in $files) {
    if ($f.FullName -match "^(.+)\.([0-9]+)$") {
        $filename = $Matches[1]
        $version = $Matches[2]

        if (-not $file_max_version.ContainsKey($filename)) {
            $file_max_version[$filename] = $version
        }
        else {
            if ([int]$version -gt [int]($file_max_version[$filename])) {
                $orig_name = "$filename.$($file_max_version[$filename])"
                Remove-Item -Path $orig_name -WhatIf:$WhatIfPreference -Confirm:$ConfirmPreference
                $file_max_version[$filename] = $version
            }
            else {
                Remove-Item -Path $f.FullName -WhatIf:$WhatIfPreference -Confirm:$ConfirmPreference
            }
        }
    }
}

foreach ($k in $file_max_version.Keys) {
    $orig_name = "$k.$($file_max_version[$k])"
    $new_name = $k

    Move-Item -Path $orig_name -Destination $new_name -Force -WhatIf:$WhatIfPreference -Confirm:$ConfirmPreference
}
