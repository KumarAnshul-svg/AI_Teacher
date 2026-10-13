$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$json = Get-Content 'tool/templates.json' -Raw | ConvertFrom-Json
$groups = $json | Group-Object level

foreach ($group in $groups) {
  $items = @($group.Group)
  $cols = 6
  $rows = [Math]::Ceiling($items.Count / $cols)
  $cell = 110
  $pad = 14
  $bmp = New-Object System.Drawing.Bitmap ($cols * $cell), ($rows * ($cell + $pad))
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.TextRenderingHint = 'AntiAlias'
  $g.Clear([System.Drawing.Color]::White)

  $magenta = New-Object System.Drawing.Pen ([System.Drawing.Color]::Magenta), 2.2
  $gray = New-Object System.Drawing.Pen ([System.Drawing.Color]::LightGray), 1.0
  $refBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(140, 130, 130, 130))
  $font = New-Object System.Drawing.Font('Arial', 52, [System.Drawing.FontStyle]::Regular)
  $nameFont = New-Object System.Drawing.Font('Consolas', 8, [System.Drawing.FontStyle]::Regular)
  $black = [System.Drawing.Brushes]::Black

  for ($i = 0; $i -lt $items.Count; $i++) {
    $col = $i % $cols
    $row = [Math]::Floor($i / $cols)
    $x0 = $col * $cell
    $y0 = $row * ($cell + $pad)
    $g.FillRectangle([System.Drawing.Brushes]::White, $x0, $y0, $cell, $cell)
    $g.DrawRectangle($gray, $x0, $y0, $cell, $cell)
    $g.DrawString($items[$i].character, $nameFont, $black, $x0 + 2, $y0 + 1)

    # Arial reference glyph centered in the cell.
    $sz = $g.MeasureString($items[$i].character, $font)
    $g.DrawString($items[$i].character, $font, $refBrush,
      ($x0 + ($cell - $sz.Width) / 2), ($y0 + ($cell - $sz.Height) / 2))

    # Template strokes mapped 0-1 to the cell.
    foreach ($stroke in $items[$i].strokes) {
      $pts = New-Object 'System.Drawing.PointF[]' ($stroke.Count)
      for ($j = 0; $j -lt $stroke.Count; $j++) {
        $pts[$j] = New-Object System.Drawing.PointF (
          ($x0 + $stroke[$j].x * $cell), ($y0 + $stroke[$j].y * $cell))
      }
      $g.DrawLines($magenta, $pts)
    }
  }
  $g.Dispose()
  $out = Join-Path 'tool' ('audit_' + $items[0].type + '.png')
  $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Write-Output "wrote $out"
}
