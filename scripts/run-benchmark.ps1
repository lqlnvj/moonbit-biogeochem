param(
  [int]$Runs = 5,
  [string]$OutputPath = 'benchmarks/benchmark-run.txt'
)

if ($Runs -lt 1) {
  throw 'Runs must be at least 1.'
}

$records = @()
$rawRuns = @()
for ($run = 1; $run -le $Runs; $run++) {
  $commandOutput = @()
  $exitCode = 0
  $elapsed = Measure-Command {
    $commandOutput = @(& moon run cmd/benchmark --target native --release 2>&1)
    $exitCode = $LASTEXITCODE
  }
  if ($exitCode -ne 0) {
    throw "Benchmark run $run failed with exit code $exitCode.`n$($commandOutput -join "`n")"
  }
  $elapsedMs = [math]::Round($elapsed.TotalMilliseconds, 3)
  $records += [PSCustomObject]@{ run = $run; elapsed_ms = $elapsedMs }
  $rawRuns += "run=$run elapsed_ms=$elapsedMs"
  $rawRuns += ($commandOutput | ForEach-Object { $_.ToString() })
}

$sorted = @($records | Sort-Object elapsed_ms)
$median = if ($sorted.Count % 2 -eq 1) {
  $sorted[[int]($sorted.Count / 2)].elapsed_ms
} else {
  ($sorted[($sorted.Count / 2) - 1].elapsed_ms + $sorted[$sorted.Count / 2].elapsed_ms) / 2.0
}
$summary = @(
  "runs=$Runs"
  "minimum_ms=$($sorted[0].elapsed_ms)"
  "median_ms=$median"
  "maximum_ms=$($sorted[$sorted.Count - 1].elapsed_ms)"
  ''
  'raw_runs:'
  $rawRuns
)

$parent = Split-Path -Parent $OutputPath
if ($parent) {
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
}
$summary | Set-Content -LiteralPath $OutputPath -Encoding utf8
$summary
