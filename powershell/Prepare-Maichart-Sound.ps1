param (
    [boolean]$Overwrite = $false,
    [string]$MusicPath,
    [string]$SoundPath,
    [string]$OutputPath,
    [string]$CriToolsPath,
    [string]$EncKey,
    [uint32]$Parallelism = 24
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
  
    $sound_path = "$USING:SoundPath/music$music_id.acb"

    if (-not (Test-Path $sound_path -PathType Leaf)) {
        Write-Warning "Sound file not found: $sound_path"
        break
    }

    $metadata_path = "$($PSItem.FullName)/Music.xml"
    if (-not (Test-Path $metadata_path -PathType Leaf)) {
        Write-Warning "Metadata not found: $metadata_path"
        break
    }

    if (-not $USING:Overwrite -and (Test-Path "$USING:OutputPath/music$music_id.mp3" -PathType Leaf)) {
        Write-Warning "Skipping existing music$music_id.mp3"
        break
    }
    
    $tmp_dir = New-TemporaryDirectory

    node.exe $USING:CriToolsPath/src/index.js acb2wavs -k $USING:EncKey -o $tmp_dir $sound_path
    ffmpeg.exe -hide_banner -loglevel error -i "$tmp_dir/stream_1.wav" -codec:a libmp3lame -qscale:a 2 "$tmp_dir/stream_1.mp3"
    Remove-Item "$tmp_dir/stream_1.wav"
    Move-Item -Path "$tmp_dir/stream_1.mp3" -Destination "$USING:OutputPath/music$music_id.mp3" -Force

    Remove-Item -Path $tmp_dir -Recurse
}
