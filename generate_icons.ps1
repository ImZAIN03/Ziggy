# Generates minimal PNG icon files for Android mipmap densities
# Run this once from the project root before building

Add-Type -AssemblyName System.Drawing

$sizes = @{
    "mipmap-mdpi"    = 48
    "mipmap-hdpi"    = 72
    "mipmap-xhdpi"   = 96
    "mipmap-xxhdpi"  = 144
    "mipmap-xxxhdpi" = 192
}

$basePath = "android\app\src\main\res"

foreach ($density in $sizes.Keys) {
    $size = $sizes[$density]
    $dir = Join-Path $basePath $density
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }

    foreach ($name in @("ic_launcher.png", "ic_launcher_round.png")) {
        $bmp = New-Object System.Drawing.Bitmap($size, $size)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::FromArgb(8, 8, 24))

        # Draw neon cyan circle (the ball)
        $cx = $size / 2
        $cy = $size * 0.4
        $r  = $size * 0.15
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 255, 255))
        $g.FillEllipse($brush, ($cx - $r), ($cy - $r), $r * 2, $r * 2)

        # Draw zigzag line
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(0, 255, 255), [float]($size * 0.04))
        $y1 = $size * 0.65
        $y2 = $size * 0.8
        $pts = @(
            [System.Drawing.PointF]::new($size * 0.15, $y1),
            [System.Drawing.PointF]::new($size * 0.38, $y2),
            [System.Drawing.PointF]::new($size * 0.62, $y1),
            [System.Drawing.PointF]::new($size * 0.85, $y2)
        )
        $g.DrawLines($pen, $pts)

        $g.Dispose()
        $bmp.Save((Join-Path $dir $name), [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        Write-Host "Created $density/$name ($size x $size)"
    }
}

Write-Host "`nIcon generation complete! Now run: flutter pub get && flutter run"
