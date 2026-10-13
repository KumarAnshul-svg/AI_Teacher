$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function Compose-Grid {
  param([string]$prefix, [string]$chars, [string]$out)
  $cell = 190
  $items = @()
  $list = if ($chars -is [array]) { $chars } else { $chars.ToCharArray() }
  foreach ($c in $list) {
    $f = "build/template_previews/$prefix$([int]$c).png"
    if (Test-Path $f) { $items += $f }
  }
  $cols = $items.Count
  $bmp = New-Object System.Drawing.Bitmap ($cols * $cell), ($cell + 30)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.Clear([System.Drawing.Color]::White)
  $nameFont = New-Object System.Drawing.Font('Consolas', 12)
  for ($i = 0; $i -lt $items.Count; $i++) {
    $img = [System.Drawing.Image]::FromFile($items[$i])
    $g.DrawImage($img, $i * $cell, 0, $cell, $cell)
    $g.DrawString(([System.IO.Path]::GetFileName($items[$i]).Split('_')[-1] -replace '\.png$', ''), $nameFont, [System.Drawing.Brushes]::Black, $i * $cell, $cell + 6)
    $img.Dispose()
  }
  $g.Dispose()
  $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Write-Output "wrote $out"
}

Compose-Grid -prefix 'small_' -chars 'abcdefghijklmnopqrstuvwxyz' -out 'tool/preview_smalls.png'
Compose-Grid -prefix 'cap_' -chars 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' -out 'tool/preview_capitals.png'
Compose-Grid -prefix 'num_' -chars '0123456789' -out 'tool/preview_numbers.png'
Compose-Grid -prefix 'line_' -chars ('|', '-', '/', '\', 'V', '^', '~', [char]0x2312) -out 'tool/preview_lines.png'
