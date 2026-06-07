param (
    [boolean]$Overwrite = $false,
    [string]$MusicPath,
    [string]$MoviePath,
    [string]$OutputPath,
    [string]$EncKey,
    [uint32]$Parallelism = 2
)


Get-ChildItem -Path $MusicPath -Directory -Filter "music*" | Foreach-Object -ThrottleLimit $Parallelism -Parallel {
    function New-TemporaryDirectory {
        $tmp = [System.IO.Path]::GetTempPath() # Not $env:TEMP, see https://stackoverflow.com/a/946017
        $name = (New-Guid).ToString("N")
        New-Item -ItemType Directory -Path (Join-Path $tmp $name)
    }

    $music_name = $PSItem.BaseName
    if (-not ($music_name -match "^music([0-9]{6})$")) {
        Write-Warning "Invalid music name: $music_name"
        break
    }
    $music_id = $Matches.1
    $music_id_int = [int]$music_id
    if ($music_id_int -ge 10000) {
        if (-not ($music_id -match "^[0-9]{2}([0-9]{4})$")) {
            Write-Warning "Invalid DX/Party music name: $music_name"
            break
        }
        $music_id = "00$($Matches.1)"
    }

    $metadata_path = "$($PSItem.FullName)/Music.xml"
    if (-not (Test-Path $metadata_path -PathType Leaf)) {
        Write-Warning "Metadata not found: $metadata_path"
        break
    }

    if (-not $USING:Overwrite -and (Test-Path "$USING:OutputPath/$music_id.mp4" -PathType Leaf)) {
        Write-Warning "Skipping existing $music_id.mp4"
        break
    }
    
    $tmp_dir = New-TemporaryDirectory

    wannacri.exe extractusm -k $USING:EncKey -o $tmp_dir "$USING:MoviePath/$music_id.dat"

    $movie_export_path = "$tmp_dir/$music_id.dat/videos"
    if (-not (Test-Path $movie_export_path -PathType Container)) {
        Write-Warning "Exported movie not found: $movie_export_path; ignoring"
        continue
    }
    $movie_file = Get-ChildItem -Path $tmp_dir -Filter "*.ivf" -Recurse
    $movie_file = $movie_file.FullName
    ffmpeg.exe -hide_banner -loglevel error -stats -hwaccel cuda -i $movie_file -c:v hevc_nvenc -rc:v vbr -cq:v 32 -qmin 30 -qmax 36 -an "$tmp_dir/$music_name.mp4"
    Move-Item -Path "$tmp_dir/$music_name.mp4" -Destination "$USING:OutputPath/$music_id.mp4" -Force

    Remove-Item -Path $tmp_dir -Recurse
}
