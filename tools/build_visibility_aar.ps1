$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
$destination = Join-Path $PSScriptRoot '..\addons\nebula_apps\nebula-visibility.aar'
New-Item -ItemType Directory -Force -Path (Split-Path $destination) | Out-Null
$manifest = @'
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="app.nebulavr.visibility">
  <queries>
    <intent><action android:name="android.intent.action.MAIN"/><category android:name="android.intent.category.LAUNCHER"/></intent>
    <intent><action android:name="android.intent.action.MAIN"/><category android:name="android.intent.category.LEANBACK_LAUNCHER"/></intent>
    <intent><action android:name="android.intent.action.MAIN"/><category android:name="com.oculus.intent.category.VR"/></intent>
    <package android:name="app.smarttube.fdroid.vr"/>
    <package android:name="com.brave.browser"/>
  </queries>
</manifest>
'@
$stream = [IO.File]::Open($destination, [IO.FileMode]::Create)
$archive = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Create)
try {
  $entry = $archive.CreateEntry('AndroidManifest.xml')
  $writer = [IO.StreamWriter]::new($entry.Open())
  $writer.Write($manifest)
  $writer.Dispose()
  $entry = $archive.CreateEntry('classes.jar')
  $jarStream = $entry.Open()
  $emptyZip = [byte[]](0x50,0x4b,0x05,0x06,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
  $jarStream.Write($emptyZip, 0, $emptyZip.Length)
  $jarStream.Dispose()
} finally {
  $archive.Dispose()
  $stream.Dispose()
}
Write-Output $destination
